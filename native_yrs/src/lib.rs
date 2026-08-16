use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::slice;
use yrs::updates::decoder::Decode;
use yrs::updates::encoder::Encode;
use yrs::{Array, Doc, Map, MapPrelim, Out, ReadTxn, StateVector, Text, TextPrelim, Transact, Update};
use serde::{Deserialize, Serialize};

// ponytail: attrs are LWW, low conflict; move to structured CRDT if attribute wars ever appear

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct BlockData {
    pub id: String,
    pub block_type: String,
    pub attributes: HashMap<String, serde_json::Value>,
    pub text: String,
}

pub struct YrsContext {
    pub doc: Doc,
}

impl YrsContext {
    pub fn new() -> Self {
        YrsContext { doc: Doc::new() }
    }
}

#[no_mangle]
pub extern "C" fn yrs_doc_create() -> *mut YrsContext {
    Box::into_raw(Box::new(YrsContext::new()))
}

#[no_mangle]
pub extern "C" fn yrs_doc_destroy(ctx: *mut YrsContext) {
    if !ctx.is_null() {
        unsafe {
            let _ = Box::from_raw(ctx);
        }
    }
}

#[no_mangle]
pub extern "C" fn yrs_doc_apply_update(ctx: *mut YrsContext, update_ptr: *const u8, update_len: usize) -> i32 {
    if ctx.is_null() || update_ptr.is_null() {
        return -1;
    }
    let ctx = unsafe { &mut *ctx };
    let slice = unsafe { slice::from_raw_parts(update_ptr, update_len) };
    
    match Update::decode_v1(slice) {
        Ok(update) => {
            let mut txn = ctx.doc.transact_mut();
            let _ = txn.apply_update(update);
            0
        }
        Err(_) => -2,
    }
}

#[no_mangle]
pub extern "C" fn yrs_doc_encode_update(
    ctx: *mut YrsContext,
    vector_ptr: *const u8,
    vector_len: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if ctx.is_null() {
        return std::ptr::null_mut();
    }
    let ctx = unsafe { &mut *ctx };
    let txn = ctx.doc.transact();
    
    let vector = if !vector_ptr.is_null() && vector_len > 0 {
        let v_slice = unsafe { slice::from_raw_parts(vector_ptr, vector_len) };
        StateVector::decode_v1(v_slice).unwrap_or_default()
    } else {
        StateVector::default()
    };

    let update_bytes = txn.encode_diff_v1(&vector);
    unsafe {
        *out_len = update_bytes.len();
    }
    let mut boxed = update_bytes.into_boxed_slice();
    let ptr = boxed.as_mut_ptr();
    std::mem::forget(boxed);
    ptr
}

#[no_mangle]
pub extern "C" fn yrs_doc_encode_vector(ctx: *mut YrsContext, out_len: *mut usize) -> *mut u8 {
    if ctx.is_null() {
        return std::ptr::null_mut();
    }
    let ctx = unsafe { &mut *ctx };
    let txn = ctx.doc.transact();
    let vector_bytes = txn.state_vector().encode_v1();
    unsafe {
        *out_len = vector_bytes.len();
    }
    let mut boxed = vector_bytes.into_boxed_slice();
    let ptr = boxed.as_mut_ptr();
    std::mem::forget(boxed);
    ptr
}

// ponytail: no move-reorder op yet; add yrs_order_move if block reordering lands.
#[no_mangle]
pub extern "C" fn yrs_order_insert(ctx: *mut YrsContext, index: u32, block_id: *const c_char) -> i32 {
    if ctx.is_null() || block_id.is_null() {
        return -1;
    }
    let ctx = unsafe { &mut *ctx };
    let id_str = unsafe { CStr::from_ptr(block_id).to_string_lossy().to_string() };
    
    // get_or_insert_* creates its own transaction internally — must run BEFORE transact_mut or the second write lock deadlocks
    let order_array = ctx.doc.get_or_insert_array("order");
    let mut txn = ctx.doc.transact_mut();
    for elem in order_array.iter(&txn) {
        if match &elem {
            Out::Any(yrs::Any::String(s)) => s.as_ref() == id_str,
            _ => false,
        } {
            return 0;
        }
    }
    order_array.insert(&mut txn, index, id_str);
    0
}

#[no_mangle]
pub extern "C" fn yrs_order_remove(ctx: *mut YrsContext, index: u32) -> i32 {
    if ctx.is_null() {
        return -1;
    }
    let ctx = unsafe { &mut *ctx };
    let order_array = ctx.doc.get_or_insert_array("order");
    let mut txn = ctx.doc.transact_mut();
    if index < order_array.len(&txn) {
        order_array.remove(&mut txn, index);
        0
    } else {
        -1
    }
}

#[no_mangle]
pub extern "C" fn yrs_block_set(
    ctx: *mut YrsContext,
    block_id: *const c_char,
    block_type: *const c_char,
    attributes_json: *const c_char,
    text: *const c_char,
) -> i32 {
    if ctx.is_null() || block_id.is_null() {
        return -1;
    }
    let ctx = unsafe { &mut *ctx };
    let id_str = unsafe { CStr::from_ptr(block_id).to_string_lossy().to_string() };
    let type_str = if block_type.is_null() {
        "paragraph".to_string()
    } else {
        unsafe { CStr::from_ptr(block_type).to_string_lossy().to_string() }
    };
    let attr_str = if attributes_json.is_null() {
        "{}".to_string()
    } else {
        unsafe { CStr::from_ptr(attributes_json).to_string_lossy().to_string() }
    };
    let text_str = if text.is_null() {
        "".to_string()
    } else {
        unsafe { CStr::from_ptr(text).to_string_lossy().to_string() }
    };

    let blocks_map = ctx.doc.get_or_insert_map("blocks");
    let order_array = ctx.doc.get_or_insert_array("order");
    let mut txn = ctx.doc.transact_mut();

    let empty_entries: [(&str, &str); 0] = [];
    let block_map = blocks_map.insert(&mut txn, id_str.clone(), MapPrelim::from(empty_entries));
    block_map.insert(&mut txn, "id", id_str.clone());
    block_map.insert(&mut txn, "type", type_str);
    block_map.insert(&mut txn, "attributes", attr_str);
    block_map.insert(&mut txn, "text", TextPrelim::new(&text_str));

    // Append to order array if not already present
    let mut exists = false;
    for elem in order_array.iter(&txn) {
        if match &elem {
            Out::Any(yrs::Any::String(s)) => s.as_ref() == id_str,
            _ => false,
        } {
            exists = true;
            break;
        }
    }
    if !exists {
        let len = order_array.len(&txn);
        order_array.insert(&mut txn, len, id_str);
    }

    0
}

#[no_mangle]
pub extern "C" fn yrs_block_text_insert(ctx: *mut YrsContext, block_id: *const c_char, index: u32, text: *const c_char) -> i32 {
    if ctx.is_null() || block_id.is_null() || text.is_null() {
        return -1;
    }
    let ctx = unsafe { &mut *ctx };
    let id_str = unsafe { CStr::from_ptr(block_id).to_string_lossy().to_string() };
    let text_str = unsafe { CStr::from_ptr(text).to_string_lossy().to_string() };

    let blocks_map = ctx.doc.get_or_insert_map("blocks");
    let mut txn = ctx.doc.transact_mut();
    if let Some(Out::YMap(b_map)) = blocks_map.get(&txn, &id_str) {
        if let Some(Out::YText(t_ref)) = b_map.get(&txn, "text") {
            t_ref.insert(&mut txn, index, &text_str);
            return 0;
        }
    }
    -1
}

#[no_mangle]
pub extern "C" fn yrs_block_text_delete(ctx: *mut YrsContext, block_id: *const c_char, index: u32, len: u32) -> i32 {
    if ctx.is_null() || block_id.is_null() {
        return -1;
    }
    let ctx = unsafe { &mut *ctx };
    let id_str = unsafe { CStr::from_ptr(block_id).to_string_lossy().to_string() };

    let blocks_map = ctx.doc.get_or_insert_map("blocks");
    let mut txn = ctx.doc.transact_mut();
    if let Some(Out::YMap(b_map)) = blocks_map.get(&txn, &id_str) {
        if let Some(Out::YText(t_ref)) = b_map.get(&txn, "text") {
            t_ref.remove_range(&mut txn, index, len);
            return 0;
        }
    }
    -1
}

#[no_mangle]
pub extern "C" fn yrs_doc_get_blocks_json(ctx: *mut YrsContext) -> *mut c_char {
    if ctx.is_null() {
        return std::ptr::null_mut();
    }
    let ctx = unsafe { &mut *ctx };
    let order_array = ctx.doc.get_or_insert_array("order");
    let blocks_map = ctx.doc.get_or_insert_map("blocks");
    let txn = ctx.doc.transact();

    let mut list = Vec::new();
    for elem in order_array.iter(&txn) {
        let id_str_opt = match &elem {
            Out::Any(yrs::Any::String(s)) => Some(s.to_string()),
            _ => None,
        };

        if let Some(id_str) = id_str_opt {
            if let Some(Out::YMap(b_map)) = blocks_map.get(&txn, &id_str) {
                let type_str = b_map.get(&txn, "type").map(|v| v.to_string(&txn)).unwrap_or_default();
                let attr_str = b_map.get(&txn, "attributes").map(|v| v.to_string(&txn)).unwrap_or_default();
                let text_str = b_map.get(&txn, "text").map(|v| v.to_string(&txn)).unwrap_or_default();

                let attrs: HashMap<String, serde_json::Value> = serde_json::from_str(&attr_str).unwrap_or_default();

                list.push(BlockData {
                    id: id_str,
                    block_type: type_str,
                    attributes: attrs,
                    text: text_str,
                });
            }
        }
    }

    let json_str = serde_json::to_string(&list).unwrap_or_else(|_| "[]".to_string());
    CString::new(json_str).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn yrs_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

#[no_mangle]
pub extern "C" fn yrs_free_bytes(ptr: *mut u8, len: usize) {
    if !ptr.is_null() && len > 0 {
        unsafe {
            let _ = Vec::from_raw_parts(ptr, len, len);
        }
    }
}

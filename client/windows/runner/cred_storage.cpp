#include "cred_storage.h"
#include <vector>

bool CredentialStorage::WriteCredential(const std::wstring& targetName, const std::wstring& userName, const std::string& secretData) {
    CREDENTIALW cred = {0};
    cred.Type = CRED_TYPE_GENERIC;
    cred.TargetName = const_cast<LPWSTR>(targetName.c_str());
    cred.UserName = const_cast<LPWSTR>(userName.c_str());
    cred.CredentialBlobSize = static_cast<DWORD>(secretData.size());
    cred.CredentialBlob = const_cast<LPBYTE>(reinterpret_cast<const BYTE*>(secretData.data()));
    cred.Persist = CRED_PERSIST_LOCAL_MACHINE;

    return CredWriteW(&cred, 0) == TRUE;
}

bool CredentialStorage::ReadCredential(const std::wstring& targetName, std::wstring& outUserName, std::string& outSecretData) {
    PCREDENTIALW pCred = nullptr;
    if (CredReadW(targetName.c_str(), CRED_TYPE_GENERIC, 0, &pCred)) {
        if (pCred->UserName) {
            outUserName = pCred->UserName;
        }
        if (pCred->CredentialBlobSize > 0 && pCred->CredentialBlob) {
            outSecretData.assign(reinterpret_cast<char*>(pCred->CredentialBlob), pCred->CredentialBlobSize);
        }
        CredFree(pCred);
        return true;
    }
    return false;
}

bool CredentialStorage::DeleteCredential(const std::wstring& targetName) {
    return CredDeleteW(targetName.c_str(), CRED_TYPE_GENERIC, 0) == TRUE;
}

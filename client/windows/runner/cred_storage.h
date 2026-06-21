#ifndef CRED_STORAGE_H_
#define CRED_STORAGE_H_

#include <string>
#include <windows.h>
#include <wincred.h>

class CredentialStorage {
public:
    static bool WriteCredential(const std::wstring& targetName, const std::wstring& userName, const std::string& secretData);
    static bool ReadCredential(const std::wstring& targetName, std::wstring& outUserName, std::string& outSecretData);
    static bool DeleteCredential(const std::wstring& targetName);
};

#endif // CRED_STORAGE_H_

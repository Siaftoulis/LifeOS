#ifndef TSNET_CLIENT_H
#define TSNET_CLIENT_H

#ifdef __cplusplus
extern "C" {
#endif

// Initialize the tsnet client
extern int InitTsnetClient(const char* hostname, const char* authKey);

// Close the tsnet client
extern void CloseTsnetClient();

#ifdef __cplusplus
}
#endif

#endif // TSNET_CLIENT_H

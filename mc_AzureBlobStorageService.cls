/**
 * mc_AzureBlobStorageService.cls
 * 
 * This class provides a service for interacting with Azure Blob Storage.
 * 
 * @author Andy Haas
 * @date 2024-11-21
 */
public with sharing class mc_AzureBlobStorageService {
    //TODO: Add this Custom Settings to store the Azure Blob Storage Account Name and Key
    private static final String STORAGE_ACCOUNT_NAME = '<storage_account_name>';
    private static final String STORAGE_ACCOUNT_KEY = '<key>';
    private static final String CONTAINER_NAME = '<container_name>';
    private static final String BASE_URL = 'https://'+ STORAGE_ACCOUNT_NAME +'.blob.core.windows.net';

    /**
     * Generates the Authorization header for the Azure Blob Storage
     * @param method The HTTP method (GET, PUT, DELETE, etc.)
     * @param blobName The name of the blob
     * @param contentType The content type of the blob
     * @param contentLength The content length of the blob
     * @param dateGmt The GMT date string
     * @return The Authorization header
     */
    private static String generateAuthorizationHeader(String method, String blobName, String contentType, String contentLength, String dateGmt) {
        // Canonicalized Headers
        String canonicalizedHeaders = 
        'x-ms-blob-type:BlockBlob\n' +
        'x-ms-date:' + dateGmt + '\n' +
        'x-ms-version:2025-01-05' + '\n';

        // Canonicalized Resource
        String canonicalizedResource = '/' + STORAGE_ACCOUNT_NAME + '/' + CONTAINER_NAME + '/' + cleanBlobName(blobName);

        // Construct String-to-Sign
        String stringToSign = method + '\n' +
        '\n' +                  // Content-Encoding
        '\n' +                  // Content-Language
        contentLength + '\n' +  // Content-Length
        '\n' +                  // Content-MD5
        contentType + '\n' +    // Content-Type
        '\n' +                  // Date (empty if x-ms-date is used)
        '\n' +                  // If-Modified-Since
        '\n' +                  // If-Match
        '\n' +                  // If-None-Match
        '\n' +                  // If-Unmodified-Since
        '\n' +                  // Range
        canonicalizedHeaders +
        canonicalizedResource;

        System.debug('Generated StringToSign: ' + stringToSign);

        // Generate HMAC-SHA256 signature
        String signedKey = EncodingUtil.base64Encode(
            Crypto.generateMac(
                'HMACSHA256',
                Blob.valueOf(stringToSign),
                EncodingUtil.base64Decode(STORAGE_ACCOUNT_KEY)
            )
        );

        return 'SharedKey ' + STORAGE_ACCOUNT_NAME + ':' + signedKey;
    }

    /**
     * Uploads a blob to the Azure Blob Storage
     * @param blobName The name of the blob to upload
     * @param contentType The content type of the blob
     * @param fileData The data for the blob
     * @return The HTTP response from the Azure Blob Storage
     */
    public static HttpResponse uploadBlob(String blobName, String contentType, Blob fileData) {
        String dateGmt = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss') + ' GMT';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + '/' + CONTAINER_NAME + '/' + cleanBlobName(blobName));
        req.setMethod('PUT');
        req.setHeader('x-ms-blob-type', 'BlockBlob');
        req.setHeader('Content-Type', contentType);
        req.setHeader('Content-Length', String.valueOf(fileData.size()));
        req.setHeader('x-ms-date', dateGmt);
        req.setHeader('x-ms-version', '2025-01-05');
        req.setHeader('Authorization', generateAuthorizationHeader('PUT', cleanBlobName(blobName), contentType, String.valueOf(fileData.size()), dateGmt));
        req.setBodyAsBlob(fileData);

        System.debug('Request: ' + req);
        System.debug('Request Body: ' + req.getBodyAsBlob());
        System.debug('Request Headers Authorization: ' + req.getHeader('Authorization'));
        System.debug('Request Headers Content-Type: ' + req.getHeader('Content-Type'));
        System.debug('Request Headers Content-Length: ' + req.getHeader('Content-Length'));
        System.debug('Request Headers x-ms-date: ' + req.getHeader('x-ms-date'));
        System.debug('Request Endpoint: ' + req.getEndpoint());

        Http http = new Http();
        return http.send(req);
    }

    /**
     * Downloads a blob from the Azure Blob Storage
     * @param blobName The name of the blob to download
     * @return The HTTP response from the Azure Blob Storage
     */
    public static HttpResponse deleteBlob(String blobName) {
        String dateGmt = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss') + ' GMT';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + '/' + CONTAINER_NAME + '/' + cleanBlobName(blobName));
        req.setMethod('DELETE');
        req.setHeader('x-ms-date', Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss') + ' GMT');
        req.setHeader('Authorization', generateAuthorizationHeader('DELETE', cleanBlobName(blobName), '', '', dateGmt));

        Http http = new Http();
        return http.send(req);
    }

    /**
     * Replaces a blob in the Azure Blob Storage
     * @param blobName The name of the blob to replace
     * @param contentType The content type of the blob
     * @param fileData The new data for the blob
     * @return The HTTP response from the Azure Blob Storage
     */
    public static HttpResponse replaceBlob(String blobName, String contentType, Blob fileData) {
        // Replace is equivalent to re-uploading with the same name
        return uploadBlob(blobName, contentType, fileData);
    }

    /**
     * Cleans the blob name to remove special characters and spaces
     * @param blobName The original blob name
     * @return The cleaned blob name
     */
    private static String cleanBlobName(String blobName) {
        return blobName.toLowerCase().replaceAll(' ', '').replaceAll('[^a-zA-Z0-9]', '');
    }
}
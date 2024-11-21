public with sharing class mc_AzureBlobStorage_UploadController {
    @AuraEnabled
    public static String uploadBlob(String blobName, String base64File, String contentType) {
        Blob fileBlob = EncodingUtil.base64Decode(base64File);
        HttpResponse response = mc_AzureBlobStorageService.uploadBlob(blobName, 'image/png', fileBlob);
        return response.getBody();
    }
}
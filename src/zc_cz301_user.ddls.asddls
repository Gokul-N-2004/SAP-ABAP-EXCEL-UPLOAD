@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'user projection view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity ZC_CZ301_USER
  as projection on ZI_CZ301_USER
{
  key EmpId,
  key DevId,
      DevDescription,

  @Semantics.largeObject: {
      mimeType: 'Mimetype',
      fileName: 'Filename',
      acceptableMimeTypes: [
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      ],
      contentDispositionPreference: #ATTACHMENT
  }
  Attachment,

  @Semantics.mimeType: true
  Mimetype,
  Filename,
  FileStatus,
  Criticality,
  TemplateStatus,
  TemplateCriticality,
  LocalCreatedBy,
  LocalCreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt,

 
  _UserDev : redirected to composition child ZC_CZ301_USER_DEV
}

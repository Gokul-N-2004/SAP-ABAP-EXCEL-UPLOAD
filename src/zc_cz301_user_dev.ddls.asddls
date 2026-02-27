@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'user development details'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define view entity ZC_CZ301_USER_DEV
  as projection on ZI_CZ301_USER_DEV
{
  key EmpId,
  key DevId,
  key SerialNo,
      ObjectType,
      ObjectName,

 
  _User : redirected to parent ZC_CZ301_USER
}

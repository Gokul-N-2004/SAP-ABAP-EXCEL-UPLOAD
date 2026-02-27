@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Child interface view for user deatils'
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: {
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define view entity ZI_CZ301_USER_DEV
  as select from ZTCZ301_USER_DEV
  association to parent ZI_CZ301_USER as _User
    on $projection.EmpId = _User.EmpId
   and $projection.DevId = _User.DevId
{
  key emp_id     as EmpId,
  key dev_id     as DevId,
  key serial_no  as SerialNo,
      object_type as ObjectType,
      object_name as ObjectName,

      _User
}

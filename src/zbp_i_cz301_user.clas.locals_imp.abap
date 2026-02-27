CLASS lhc_User DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS uploadExcelData FOR MODIFY
      IMPORTING keys FOR ACTION User~uploadExcelData RESULT result.

    METHODS DownloadExcel FOR MODIFY
      IMPORTING keys FOR ACTION User~DownloadExcel RESULT result.

    METHODS fillfilestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR User~FillFileStatus.

    METHODS fillselectedstatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR User~FillSelectedStatus.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR User RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR User RESULT result.
ENDCLASS.

CLASS lhc_User IMPLEMENTATION.

  METHOD DownloadExcel.
    TYPES: BEGIN OF ty_exl_file,
             emp_id   TYPE string,
             dev_id   TYPE string,
             dev_desc TYPE string,
             obj_type TYPE string,
             obj_name TYPE string,
           END OF ty_exl_file.
    DATA: lt_template TYPE STANDARD TABLE OF ty_exl_file.

    " Create Excel Template
    DATA(lo_write_access) = xco_cp_xlsx=>document->empty( )->write_access( ).
    DATA(lo_worksheet) = lo_write_access->get_workbook( )->worksheet->at_position( 1 ).
    lt_template = VALUE #( ( emp_id = 'User Id' dev_id = 'Dev Id' dev_desc = 'Desc' obj_type = 'Type' obj_name = 'Name' ) ).

    lo_worksheet->select( xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( )
      )->row_stream( )->operation->write_from( REF #( lt_template ) )->execute( ).

    DATA(lv_file_content) = lo_write_access->get_file_content( ).

    " Update record with template file
    MODIFY ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User
      UPDATE FIELDS ( Attachment Filename Mimetype TemplateStatus )
      WITH VALUE #( FOR ls_key IN keys (
          %tky           = ls_key-%tky
          Attachment     = lv_file_content
          Filename       = 'template.xlsx'
          Mimetype       = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          TemplateStatus = 'Present'
      ) ).

    " Return result to UI
    READ ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_user).
    result = VALUE #( FOR ls_user IN lt_user ( %tky = ls_user-%tky %param = ls_user ) ).
  ENDMETHOD.

  METHOD uploadExcelData.
    READ ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_user).

    DATA(ls_user) = lt_user[ 1 ].
    CHECK ls_user-Attachment IS NOT INITIAL.

    " Read Excel Content
    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content( ls_user-Attachment )->read_access( ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).

    TYPES: BEGIN OF ty_excel,
             emp_id TYPE string, dev_id TYPE string, dev_desc TYPE string, obj_type TYPE string, obj_name TYPE string,
           END OF ty_excel.
    DATA lt_excel TYPE STANDARD TABLE OF ty_excel.

    lo_worksheet->select( xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( )
      )->row_stream( )->operation->write_to( REF #( lt_excel ) )->execute( ).

    DELETE lt_excel INDEX 1. " Remove Header

    " Create Children (UserDev)
    MODIFY ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User CREATE BY \_UserDev
      FIELDS ( EmpId DevId SerialNo ObjectType ObjectName )
      WITH VALUE #( (
        %tky = ls_user-%tky
        %target = VALUE #( FOR ls_row IN lt_excel INDEX INTO lv_idx (
            %cid       = 'CID_DEV' && |{ lv_idx }|
            EmpId      = ls_user-EmpId
            DevId      = ls_user-DevId
            SerialNo   = lv_idx
            ObjectType = CONV #( ls_row-obj_type )
            ObjectName = CONV #( ls_row-obj_name ) ) ) ) ).

    " Update Status
    MODIFY ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User UPDATE FIELDS ( FileStatus )
      WITH VALUE #( ( %tky = ls_user-%tky FileStatus = 'Excel Uploaded' ) ).
  ENDMETHOD.

  METHOD fillfilestatus.
    MODIFY ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User UPDATE FIELDS ( FileStatus TemplateStatus )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                      FileStatus = 'File not Selected'
                                      TemplateStatus = 'Absent' ) ).
  ENDMETHOD.

  METHOD fillselectedstatus.
    READ ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User FIELDS ( Attachment ) WITH CORRESPONDING #( keys ) RESULT DATA(lt_user).

    MODIFY ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User UPDATE FIELDS ( FileStatus )
      WITH VALUE #( FOR ls IN lt_user (
        %tky = ls-%tky
        FileStatus = COND #( WHEN ls-Attachment IS INITIAL THEN 'File not Selected' ELSE 'File Selected' )
      ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_cz301_user IN LOCAL MODE
      ENTITY User FIELDS ( FileStatus ) WITH CORRESPONDING #( keys ) RESULT DATA(lt_users).

    result = VALUE #( FOR user IN lt_users (
      %tky = user-%tky
      %action-uploadExcelData = COND #( WHEN user-FileStatus = 'File Selected'
                                        THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
      %action-DownloadExcel   = if_abap_behv=>fc-o-enabled
      %assoc-_UserDev         = if_abap_behv=>fc-o-enabled
    ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.
ENDCLASS.

connection: "postgres-pgcrypto"

include: "*.view.lkml"         # include all views in this project
include: "*.dashboard.lookml"  # include all dashboards in this project

explore: patient {
  join: generate_iv_key {
    type:left_outer
    relationship: many_to_one
    sql_on: ${patient.uuid} = ${generate_iv_key.uuid} ;;
  }
  access_filter: {
    field: patient.uuid
    user_attribute: uuid
  }
}

view: generate_iv_key {
  # this will make it so you generate key and iv on the neccessary accounts once per query
  derived_table: {
    sql:
    WITH uuid_cte as (
      SELECT patient.uuid FROM ${patient.SQL_TABLE_NAME} as patient -- replace FROM clause with FROM your_account_table
      WHERE patient.uuid IN {{ _user_attributes["uuid"] | replace: ",","','" | append: "')" | prepend: "('" }}
    )
    SELECT uuid, key_iv.key, key_iv,iv
    FROM (
      SELECT (
        my_test_func(
         LEFT('{{ _user_attributes["global_key"] }}',3) || uuid_cte.uuid || RIGHT('{{ _user_attributes["global_key"] }}',4 )
        ) ).*, uuid_cte.uuid FROM uuid_cte
      ) as key_iv
     ;;
  }
  dimension: uuid {  }
  dimension: key {
    type: string
    sql: decode(${TABLE}.key, 'base64') ;;
  }
  dimension: iv {
    type: string
    sql: decode(${TABLE}.iv, 'base64') ;;
  }
}

view: patient {
  derived_table: {
    sql:
    WITH patient_cte (first_name,uuid) as (
      VALUES ('8+CfXwSe5vdCPTrpDPv70w=='::text, 'pass'::text), ('8+CfXwSe5vdCPTrpDPv70w=='::text,'this_record'::text)
    )
    SELECT * from patient_cte  ;;
  }

  dimension: uuid {
    type: string
    sql: ${TABLE}.uuid ;;
  }

  dimension: first_name_encrypted {
    type: string
    sql: ${TABLE}.first_name  ;;
  }

  dimension: first_name_decrypted  {
    type: string
    sql:
      convert_from (
        decrypt_iv(
          decode(${first_name_encrypted},'base64')
          , ${generate_iv_key.key}
          , ${generate_iv_key.iv}
          , 'aes-cbc/pad:pkcs')
        , 'utf-8')
        ;;
  }
}

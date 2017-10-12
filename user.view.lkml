explore: user {}
view: user {
  derived_table: {
    sql: SELECT 'pass'::text as uuid, '8+CfXwSe5vdCPTrpDPv70w=='::text as first_name ;;
  }
  dimension: uuid {
    type: string
    sql: ${TABLE}.uuid ;;
  }
  dimension: first_name {
    hidden: yes
    type: string
    sql: ${TABLE}.first_name  ;;
  }
  dimension: global_key {
    type: string
    sql: '{{ _user_attributes["global_key"] }}' ;;
  }
  dimension: password {
    type: string
    sql: LEFT(${global_key},3) || ${uuid} || RIGHT(${global_key},4) ;;
  }


  dimension: first_name_decrypted  {
    type: string
    sql:
  ( SELECT
    convert_from(
      decrypt_iv(
        decode(${first_name},'base64'),
        decode(
          key_iv.key
          ,'base64'),
        decode(
          key_iv.iv
          ,'base64')
        , 'aes-cbc/pad:pkcs')
      , 'utf-8')
   FROM ( SELECT (my_test_func(${password})).* ) as key_iv )

    ;;
  }

}

  METHOD generate_random.
    " 1. Karakter seti
    DATA(lv_chars)    = iv_randomset.
    DATA(lv_char_len) = strlen( lv_chars ).

    " 2. Sonuç stringi başlat
    rv_string = ``.

    " 3. Seed olarak sistem zamanını al ve integer'a çevir
    DATA(lv_seed_str) = cl_abap_context_info=>get_system_time( ). " HHMMSS
    DATA(lv_seed_int) = CONV i( lv_seed_str ).

    " 4. Döngü ile string oluştur
    DO iv_length TIMES.
      " 4a. 0..(karakter seti uzunluğu-1) arasında index üret
      DATA(lv_index) = ( lv_seed_int + sy-index * 17 ) MOD lv_char_len.

      " 4b. Karakteri seç ve string'e ekle
      rv_string = rv_string && lv_chars+lv_index(1).

      " 4c. Seed'i değiştir (farklı karakterler için)
      lv_seed_int = lv_seed_int + sy-index * 31.
    ENDDO.
  ENDMETHOD.
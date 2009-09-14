-- Galactica Lua configuration file

-- some functions used in the keybindings
function remove_and_next ()
  remove_current_track ()
  play_next ()
end

function seek_f_60 ()
  seek (true, 60)
end

function seek_f_10 ()
  seek (true, 10)
end

function seek_r_10 ()
  seek (false, 10)
end

function seek_r_60 ()
  seek (false, 60)
end

function download_current_track ()
  no_position_update (true)
  os.execute ("wget " .. current_track ())
  no_position_update (false)
end

-- The real key-bindins
key_104 = seek_r_10
key_106 = seek_r_60
key_107 = seek_f_60
key_108 = seek_f_10
key_110 = play_next
key_112 = play_prev
key_114 = remove_and_next
key_32 = toggle_play_pause
key_65 = seek_f_60
key_66 = seek_r_60
key_67 = seek_f_10
key_68 = seek_r_10
key_113 = quit
key_27 = quit
key_100 = download_current_track

auto_auth {
  method "approle" {
    config = {
      role_id_file_path   = "/vault/data/roleid"
      secret_id_file_path = "/vault/data/secretid"
      remove_secret_id_file_after_reading = false
    }
  }

  
}

template {
    source = "/vault/config/agent/template.tpl"
    destination = "/vault/data/vars.env"
}
# Vault

## Prepare o seu ambiente
```sh
kubectl config use-context vault
kubectl get pods -l app.kubernetes.io/instance=vault
```

## Inicializar
```sh
kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
cat cluster-keys.json | jq -r ".unseal_keys_b64[]"
```

## Abrir
```
VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
```

## Recuperar o root token
```
cat cluster-keys.json | jq -r ".root_token"
```

## Login 
```sh
kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh
```

Em seguida

```sh
vault login
```

## Ativar mecanismo KV
```sh
vault secrets enable -path=secret kv-v2
```

## Criar uma secret
```sh
vault kv put secret/webapp/config username="static-user" password="static-password"
```


## Ativar e configurar autenticação do Kubernetes
```sh
vault auth enable kubernetes
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

```



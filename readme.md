# Vault

## Objetivos
* Inicializar e Desbloquear o Vault
  * Definir o número de chaves distribuídas e o número de chaves necessárias para desbloqueio
  * Desbloquear o Vault
* Habilitar o mecanismo de armazenamento de chaves
* Criar as chaves
* Ler as chaves
* Proteger as chaves com políticas
* Criar um token somente leitura
* Consumir as chaves


## Executar o Vault
```sh
docker compose up -d vault
```

>Há outros serviços no ```docker-compose``` que serão utilizados em outro momento.

A interface gráfica do Vault pode ser acessada por http://localhost:8200


> Para executar os comando de inicialização e abertura do Vault será necessário abrir uma sessão com o _container_.

```sh
docker exec -it vault sh
```

## Inicializar

Inicializa o Vault com 3 chaves compartilhadas e pelo menos duas necessárias, salvando as chaves em formato json na pasta de configurações

```sh
vault operator init -key-shares=3 -key-threshold=2 -format=json > /vault/data/cluster-keys.json
```

Verifique as chaves e o token inicial usando o comando:
```sh
cat /vault/data/cluster-keys.json
```

O resultado deve ser parecido com este:
```
{
  "unseal_keys_b64": [
    "NKkkR7JS11K8W+xnHS1I432YmVAzwCl35el9cEXdidcx",
    "Nb/PZEigX6XSBz5ie7VnCenH6T4WKoVrPgpWMLp7Xwry",
    "/yFYCQHj9SkqTFWtiQsFVFjJhcbxdwJwlZcxYDx5MStH"
  ],
  "unseal_keys_hex": [
    "34a92447b252d752bc5bec671d2d48e37d98995033c02977e5e97d7045dd89d731",
    "35bfcf6448a05fa5d2073e627bb56709e9c7e93e162a856b3e0a5630ba7b5f0af2",
    "ff21580901e3f5292a4c55ad890b055458c985c6f1770270959731603c79312b47"
  ],
  "unseal_shares": 3,
  "unseal_threshold": 2,
  "recovery_keys_b64": [],
  "recovery_keys_hex": [],
  "recovery_keys_shares": 5,
  "recovery_keys_threshold": 3,
  "root_token": "hvs.KqEKr5W6qchg1HMDcFaOtz3A"
}

```
## Desbloquear
O vault está bloqueado para utilização, desbloqueio-o usando 2 das 3 chaves distintas presentes no arquivo cluster-keys.json (unseal_keys_b64):
```sh
KEY1=[chave aqui]
KEY2=[chave aqui]
````

Após atribuir os valores, execute os comandos para desbloquear o vault
```sh
vault operator unseal $KEY1
vault operator unseal $KEY2
```

A saída deve mostrar que o Vault está inicializado e desbloqueado:
```
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
```

## Acessar
Faça o login no Vault usando o root token presente no arquivo ``cluster-keys.json``

```sh
vault login <token>
```

A mensagem de saída deve ser parecida com esta:
```
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

```

## Ativar mecanismo KV
Ative o mecanismo KV (Key Value) para armamzenar seus segredos.

```sh
vault secrets enable -path=catalog kv-v2
```

## Criar as secrets
Com o mecanismo KV habilitado, crie suas secrets

```sh
vault kv put catalog/settings/mongo connectionString="mongodb://mongodb:27017" databaseName="Catalog" collectionName="CatalogItems"
```

Verifique se os valores foram gravados corretamente executando o comando:

```sh
vault kv get catalog/settings/mongo
```

Os valores podem ser recuperados via API também.

> Importante: Execute este comando fora do container.
```sh
curl -i http://127.0.0.1:8200/v1/catalog/data/settings/mongo -H 'Authorization: Bearer <token>'
```

## Gerenciando políticas

Crie uma policy que permita somente leitura das secrets:

```sh
vault policy write readers - <<EOF
path "catalog/data/settings/mongo" {
  capabilities = ["read"]
}
EOF
```

Crie um novo token para esta policy:

```sh
vault token create -policy=readers -format=json > /vault/data/reader-token.json
```

Recupere o novo token fazendo a leitura do arquivo:

```sh
cat /vault/data/reader-token.json
```

Faça o login com este novo token:

```sh
vault login <token>
```

Tente excluir as chaves:
```sh
vault kv delete catalog/settings/mongo
```

A saída deve ser:
```
Error deleting catalog/data/settings/mongo: Error making API request.

URL: DELETE http://127.0.0.1:8200/v1/catalog/data/settings/mongo
Code: 403. Errors:

* 1 error occurred:
	* permission denied
```

## Configurando o Agent
Efetue o logon novamente com o ```root_token```
```sh
vault login <token>
```

Habilite o mecanismo de autenticação de AppRole
```sh
vault auth enable approle
```

Configure uma AppRole para ser usada pelo ```agent```.
```sh
vault write auth/approle/role/vault-agent \
    secret_id_ttl=1440m \
    token_num_uses=0 \
    token_ttl=1440m \
    token_max_ttl=1440m \
    secret_id_num_uses=0 \
    token_policies=readers
```



Leia a chave, capture o ID da role:
```sh
vault read auth/approle/role/vault-agent/role-id -format=json 
```
Armazene o valor de ```data.role_id``` no arquivo /vault/data/roleid
```sh
echo 763562cd-0ba0-8e3d-025c-732214d94538 > /vault/data/roleid
```

Grave o secret ID:
```sh
vault write -f auth/approle/role/vault-agent/secret-id  -format=json
```

Armazene-o valor de ```data.secret_id``` em um arquivo:

```sh
 echo 0b5631e6-227b-a18b-06ea-11c4076933c1 /vault/data/secretid
```

Ative a aplicação ```catalog-api```
```sh
docker compose up -d catalog-api 
```

Verifique se ela está respondendo

```sh
curl -i http://localhost:8080/catalog/items
```

```
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Date: Thu, 29 Sep 2022 02:55:28 GMT
Server: Kestrel
Transfer-Encoding: chunked
version: 1

[]      
```

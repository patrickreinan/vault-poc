{{ with secret "catalog/settings/mongo" -}}
export MONGODB__ConnectionString={{ .Data.data.connectionString }}
export MONGODB__CollectionName={{ .Data.data.collectionName }}
export MONGODB__DatabaseName={{ .Data.data.databaseName }}
{{- end }}


{{ with secret "catalog/settings/mongo" -}}
export MONGO__ConnectionString={{ .Data.data.connectionString }}
export MONGO__CollectionName={{ .Data.data.collectionName }}
export MONGO__DatabaseName={{ .Data.data.databaseName }}
{{- end }}


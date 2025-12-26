Mox.defmock(CrucibleModelRegistry.Storage.Mock, for: CrucibleModelRegistry.Storage)

Mox.defmock(CrucibleModelRegistry.Storage.S3ClientMock,
  for: CrucibleModelRegistry.Storage.S3Client
)

Mox.defmock(CrucibleModelRegistry.Storage.HuggingFaceClientMock,
  for: CrucibleModelRegistry.Storage.HuggingFaceClient
)

defmodule CrucibleModelRegistry.Pins.Receipt do
  @moduledoc "Receipt emitted by artifact pin fetch and verification operations."

  alias CrucibleModelRegistry.Pins.ArtifactPin

  @enforce_keys [:action, :repo_id, :revision, :destination, :files, :created_at]
  defstruct [:action, :repo_id, :revision, :destination, :files, :created_at, metadata: %{}]

  @type action :: :fetch | :verify
  @type file_status :: :fetched | :skipped | :verified
  @type file_receipt :: %{
          required(:path) => String.t(),
          required(:sha256) => String.t(),
          required(:size_bytes) => non_neg_integer(),
          required(:status) => file_status()
        }

  @type t :: %__MODULE__{
          action: action(),
          repo_id: String.t(),
          revision: String.t(),
          destination: Path.t(),
          files: [file_receipt()],
          created_at: DateTime.t(),
          metadata: map()
        }

  @doc "Builds an operation receipt from a pin and per-file receipts."
  @spec new(action(), ArtifactPin.t(), Path.t(), [file_receipt()], keyword()) :: t()
  def new(action, %ArtifactPin{} = pin, destination, files, opts \\ []) do
    %__MODULE__{
      action: action,
      repo_id: pin.repo_id,
      revision: pin.revision,
      destination: Path.expand(destination),
      files: files,
      created_at: Keyword.get(opts, :created_at, DateTime.utc_now()),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end
end

defmodule CrucibleModelRegistry.ProviderCompatibility do
  @moduledoc """
  Provider/model/artifact compatibility metadata for pinned model artifacts.

  This module validates declared support surfaces only. It does not rank,
  promote, or choose artifacts.
  """

  @derive Jason.Encoder
  defstruct provider_kind: nil,
            model_id: nil,
            model_family: nil,
            artifact_ref: nil,
            runtime_profile: nil,
            supported_signals: [],
            required_signals: [],
            unsupported_signals: [],
            supported_active_controls: [],
            required_active_controls: [],
            metadata: %{}

  @type t :: %__MODULE__{}

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, Exception.t()}
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    {:ok, new!(attrs)}
  rescue
    exception -> {:error, exception}
  end

  @spec new!(map() | keyword()) :: t()
  def new!(attrs) when is_list(attrs), do: attrs |> Map.new() |> new!()

  def new!(attrs) when is_map(attrs) do
    %__MODULE__{
      provider_kind: label(field(attrs, :provider_kind)),
      model_id: label(field(attrs, :model_id)),
      model_family: label(field(attrs, :model_family)),
      artifact_ref: label(field(attrs, :artifact_ref)),
      runtime_profile: label(field(attrs, :runtime_profile)),
      supported_signals: labels(field(attrs, :supported_signals, [])),
      required_signals: labels(field(attrs, :required_signals, [])),
      unsupported_signals: labels(field(attrs, :unsupported_signals, [])),
      supported_active_controls: labels(field(attrs, :supported_active_controls, [])),
      required_active_controls: labels(field(attrs, :required_active_controls, [])),
      metadata: field(attrs, :metadata, %{})
    }
  end

  @spec validate([t()], map() | keyword() | t()) ::
          {:ok, t()} | {:error, {:incompatible_provider, [term()]}}
  def validate(records, requirement) when is_list(records) do
    requirement = normalize(requirement)

    case Enum.find(records, &identity_match?(&1, requirement)) do
      nil ->
        {:error, {:incompatible_provider, identity_mismatch_reasons(records, requirement)}}

      %__MODULE__{} = record ->
        case requirement_reasons(record, requirement) do
          [] -> {:ok, record}
          reasons -> {:error, {:incompatible_provider, reasons}}
        end
    end
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = compatibility), do: Map.from_struct(compatibility)

  defp normalize(%__MODULE__{} = compatibility), do: compatibility
  defp normalize(attrs), do: new!(attrs)

  defp identity_match?(%__MODULE__{} = record, %__MODULE__{} = requirement) do
    optional_match?(record.provider_kind, requirement.provider_kind) and
      optional_match?(record.model_id, requirement.model_id) and
      optional_match?(record.artifact_ref, requirement.artifact_ref)
  end

  defp optional_match?(_record_value, nil), do: true
  defp optional_match?(record_value, required_value), do: record_value == required_value

  defp identity_mismatch_reasons([], _requirement), do: [:no_provider_compatibility_records]

  defp identity_mismatch_reasons(_records, %__MODULE__{} = requirement) do
    [
      maybe_reason(:provider_kind_mismatch, requirement.provider_kind),
      maybe_reason(:model_id_mismatch, requirement.model_id),
      maybe_reason(:artifact_ref_mismatch, requirement.artifact_ref)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp maybe_reason(_kind, nil), do: nil
  defp maybe_reason(kind, value), do: {kind, value}

  defp requirement_reasons(%__MODULE__{} = record, %__MODULE__{} = requirement) do
    []
    |> maybe_unsupported(
      :unsupported_signals,
      unsupported(
        requirement.required_signals,
        record.supported_signals,
        record.unsupported_signals
      )
    )
    |> maybe_unsupported(
      :unsupported_active_controls,
      unsupported(
        requirement.required_active_controls,
        record.supported_active_controls,
        []
      )
    )
  end

  defp unsupported(required, supported, explicitly_unsupported) do
    Enum.filter(required, fn value ->
      value in explicitly_unsupported or value not in supported
    end)
  end

  defp maybe_unsupported(reasons, _kind, []), do: reasons
  defp maybe_unsupported(reasons, kind, values), do: [{kind, values} | reasons]

  defp labels(values) when is_list(values),
    do: values |> Enum.map(&label/1) |> Enum.reject(&is_nil/1)

  defp labels(nil), do: []
  defp labels(value), do: [label(value)]

  defp label(nil), do: nil
  defp label(value) when is_atom(value), do: Atom.to_string(value)
  defp label(value) when is_binary(value), do: value
  defp label(value), do: to_string(value)

  defp field(map, field, default \\ nil),
    do: Map.get(map, field, Map.get(map, Atom.to_string(field), default))
end

defmodule Sunstone.Accounts.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :sunstone,
    error_handler: Sunstone.Accounts.ErrorHandler,
    module: Sunstone.Accounts.Guardian

  # If there is a session token, validate it
  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyCookie, claims: %{"typ" => "access"}

  # If there is an authorization header, validate it
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}


  # Load the user if either of the verifications worked
  plug Guardian.Plug.LoadResource, allow_blank: true
end


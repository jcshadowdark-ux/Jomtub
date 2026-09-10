# Jomtub Sport

ASP.NET Core 8 clothing shop with product catalog, filters, local shopping cart, checkout and Supabase order storage.

## Run

Set `Supabase__AnonKey` to the Supabase anon key, then run `dotnet run`. Apply `supabase/schema.sql` in Supabase SQL Editor before enabling order storage.

The Supabase URL is configured as `https://rbexmkbvfzksnwaxcivw.supabase.co` and can be overridden with `Supabase__Url`.

## Deploy to IIS

Publish with `dotnet publish -c Release -o publish`, install the ASP.NET Core Hosting Bundle on the Windows Server, create an IIS site pointing to the `publish` folder, and set `Supabase__AnonKey` as an environment variable when possible.

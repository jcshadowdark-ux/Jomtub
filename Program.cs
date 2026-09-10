var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/api/config", (IConfiguration config) => Results.Ok(new
{
    supabaseUrl = config["Supabase:Url"] ?? "https://rbexmkbvfzksnwaxcivw.supabase.co",
    supabaseAnonKey = config["Supabase:AnonKey"] ?? ""
}));

app.MapFallbackToFile("index.html");
app.Run();

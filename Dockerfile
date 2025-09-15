# 1) Build stage
FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build

ARG Configuration=Release
WORKDIR /src

# copy csproj and restore as separate layer
COPY ["test_api/test_api.csproj", "test_api/"]
RUN dotnet restore "test_api/test_api.csproj"

# copy everything else and build/publish
COPY test_api/. ./test_api/
WORKDIR /src/test_api
RUN dotnet publish "test_api.csproj" -c $Configuration -o /app/publish --no-restore

# 2) Runtime stage
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1 AS runtime
WORKDIR /app

# Environment variables
ENV ASPNETCORE_URLS=http://+:80
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

# copy published output from build stage
COPY --from=build /app/publish .

# Run as non-root user (recommended)
RUN addgroup --system app && adduser --system --ingroup app app
USER app

# Expose port
EXPOSE 80

# Start app
ENTRYPOINT ["dotnet", "test_api.dll"]

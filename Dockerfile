# --- Stage 1: The "Builder" Stage ---
# Start from the full .NET SDK image. We name this stage "build" so we can refer to it later.
FROM registry.access.redhat.com/ubi8/dotnet-90 AS build
WORKDIR /opt/app-root/src
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Copy only the project file first. Docker caches this layer. If the .csproj file doesn't change, 
# Docker won't re-run 'dotnet restore' on subsequent builds, speeding things up.
COPY *.csproj .
RUN dotnet restore

# Now copy the rest of the source code, setting ownership to 1001:0
COPY --chown=1001:0 . .

# Build the application. This compiles the code and prepares it for publishing.
RUN dotnet build -c Release -o /opt/app-root/app/build
# Publish the application. This compiles the code and puts the output in /app/publish.
RUN dotnet publish -c Release -o /opt/app-root/app/publish


# --- Stage 2: The "Final" Stage ---
# Start from a clean, minimal runtime image. This will be our production image.
FROM registry.access.redhat.com/ubi8/dotnet-90-runtime
WORKDIR /opt/app-root/app

# This is the key instruction! Copy ONLY the compiled output from the "build" stage
# into the current stage.
COPY --from=build /opt/app-root/app/publish .

# Set the command to run when the container starts.
ENTRYPOINT ["dotnet", "openshiftdotnet.dll"]
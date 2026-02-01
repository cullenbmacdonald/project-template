// Example Go server entry point
// Customize or replace for your tech stack

package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

// Version info (injected at build time via -ldflags)
var (
	Version    = "dev"
	CommitHash = "unknown"
	BuildTime  = "unknown"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/api/v1/hello", helloHandler)

	log.Printf("Server starting on port %s (version: %s, commit: %s)", port, Version, CommitHash)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func healthHandler(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{
		"status":      "ok",
		"version":     Version,
		"commit_hash": CommitHash,
		"build_time":  BuildTime,
	})
}

func helloHandler(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{
		"message": "Hello, World!",
	})
}

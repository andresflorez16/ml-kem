package main

import (
	"crypto/tls"
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	certFile := os.Getenv("MLKEM_CERT")
	keyFile := os.Getenv("MLKEM_KEY")
	port := os.Getenv("PORT")
	if port == "" {
		port = "8445"
	}
	if certFile == "" || keyFile == "" {
		log.Fatal("defina MLKEM_CERT y MLKEM_KEY")
	}

	cert, err := tls.LoadX509KeyPair(certFile, keyFile)
	if err != nil {
		log.Fatal(err)
	}

	srv := &http.Server{
		Addr: "127.0.0.1:" + port,
		TLSConfig: &tls.Config{
			Certificates:     []tls.Certificate{cert},
			MinVersion:       tls.VersionTLS13,
			CurvePreferences: []tls.CurveID{tls.X25519MLKEM768},
		},
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.TLS != nil {
				log.Printf("group=%s id=%d", r.TLS.CurveID.String(), r.TLS.CurveID)
			}
			fmt.Fprint(w, "ok\n")
		}),
	}

	log.Printf("go listening %s", port)
	log.Fatal(srv.ListenAndServeTLS("", ""))
}

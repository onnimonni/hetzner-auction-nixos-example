package main

import (
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/user"
	"runtime"
	"time"
)

func handler(w http.ResponseWriter, r *http.Request) {
	hostname, err := os.Hostname()
	if err != nil {
		log.Fatalf("failed to get hostname: %v", err)
	}
	currentUser, err := user.Current()
	if err != nil {
		log.Fatalf("failed to get username: %v", err)
	}
	localIP, err := getLocalIP()
	if err != nil {
		log.Fatalf("failed to get local IP: %v", err)
	}

	fmt.Fprintf(w, "Time:          %s\n", getFormattedTime())
	fmt.Fprintf(w, "Hostname:      %s\n", hostname)
	fmt.Fprintf(w, "Username:      %s\n", currentUser.Username)
	fmt.Fprintf(w, "Local IP:      %s\n", localIP.String())
	fmt.Fprintf(w, "Compiled with: %s\n", runtime.Version())
	// TODO: Disable to see if we can update this without nix flake update
	// fmt.Fprintf(w, "Process ID:    %s\n", os.Getpid())
	// Get the process pid of this service
}

func getLocalIP() (net.IP, error) {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return net.IP{}, err
	}
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP, nil
			}
		}
	}

	return net.IP{}, errors.New("no local IP address found")
}

func getFormattedTime() string {
	now := time.Now()
	zone, _ := now.Zone()
	return now.Format("2006-01-02 03:04:05 PM") + fmt.Sprintf(" (%s)", zone)
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", handler)
	fmt.Printf("listening on :%s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

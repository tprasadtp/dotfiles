package main

import (
	"bufio"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
)

// Info Provide node and task info
type Info struct {
	Node NodeInfo `json:"node" yaml:"node" hcl:"node"`
	Job  JobInfo  `json:"job" yaml:"job" hcl:"job"`
}

// NodeInfo Info on current node
type NodeInfo struct {
	Name  string `json:"name" yaml:"name" hcl:"name"`
	Index int    `json:"index" yaml:"index" hcl:"index"`
}

// JobInfo from PBS env variables
type JobInfo struct {
	// Name of the job
	Name string `json:"name" yaml:"name" hcl:"name"`
	// User who submitted the job
	Authorization string `json:"authorization" yaml:"authorization" hcl:"authorization"`
	Entitlement   string `json:"entitlement" yaml:"entitlement" hcl:"entitlement"`
	ID            int    `json:"id" yaml:"id" hcl:"id"`
	// Number of nodes
	NodeCount int      `json:"nodeCount" yaml:"nodeCount" hcl:"nodeCount"`
	Nodes     []string `json:"nodes" yaml:"nodes" hcl:"nodes"`
	PPN       int      `json:"ppn" yaml:"ppn" hcl:"ppn"`
	// Tasks
	TaskCount int `json:"taskCount" yaml:"taskCount" hcl:"taskCount"`
	Walltime  int `json:"walltime" yaml:"walltime" hcl:"walltime"`
	// Job Queue
	Queue string `json:"queue" yaml:"queue" hcl:"queue"`
}

// lookup env vars and typecast to int
func lookupEnvInt(key string) int {
	val, ok := os.LookupEnv(key)
	if !ok {
		return -1
	}

	if val, err := strconv.Atoi(val); err == nil {
		return val
	}
	return -1
}

func nodefile2NodeList() []string {
	nodefilePath, nodefileEnvPresent := os.LookupEnv("PBS_NODEFILE")
	if !nodefileEnvPresent {
		log.Printf("[ERROR] Nodefile not preset. Not running inside a job?")
		return nil
	}

	file, err := os.Open(nodefilePath)
	if err != nil {
		log.Printf("[ERROR] Faied to opnen nodefile? check if job has not exceeded walltime")
		return nil
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Split(bufio.ScanLines)
	var nodes []string

	for scanner.Scan() {
		nodes = append(nodes, scanner.Text())
	}
	return nodes
}

// getHostname Get name of current host
func getHostname() string {
	host, err := os.Hostname()
	if err == nil {
		return host
	}
	log.Printf("[WARN] Failed to get nodename, %+v", err)
	return os.Getenv("HOSTNAME")

}

func getJobInfo() Info {
	return Info{
		Node: NodeInfo{
			Name:  getHostname(),
			Index: lookupEnvInt("PBS_NODENUM"),
		},
		Job: JobInfo{
			Name:          os.Getenv("PBS_JOBNAME"),
			Authorization: os.Getenv("PBS_O_LOGNAME"),
			Entitlement:   os.Getenv("MOAB_ACCOUNT"),
			ID:            lookupEnvInt("MOAB_JOBID"),
			NodeCount:     lookupEnvInt("PBS_NUM_NODES"),
			Nodes:         nodefile2NodeList(),
			PPN:           lookupEnvInt("PBS_NUM_PPN"),
			TaskCount:     lookupEnvInt("PBS_NUM_PPN"),
			Walltime:      lookupEnvInt("PBS_WALLTIME"),
			Queue:         os.Getenv("PBS_QUEUE"),
		},
	}
}

func server(port int) {
	log.Printf("[INFO] Running on port: %d", port)
	mux := http.NewServeMux()
	s := http.Server{Addr: fmt.Sprintf(":%d", port), Handler: mux}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// SIGNAL handlers
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, os.Kill)

	go func() {
		oscall := <-c
		log.Printf("[INFO] OS Signal:%+v", oscall)
		cancel()
	}()

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[INFO] %s %s", r.Method, r.RequestURI)
		w.Write([]byte("OK"))
	})

	mux.HandleFunc("/info", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[INFO] %s %s", r.Method, r.RequestURI)
		if err := json.NewEncoder(w).Encode(getJobInfo()); err != nil {
			log.Printf("[ERROR] Failed to parse response to JSON")
			w.WriteHeader(http.StatusInternalServerError)
		}
		w.Header().Set("Content-Type", "application/json")
	})

	mux.HandleFunc("/shutdown", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[INFO] %s %s", r.Method, r.RequestURI)
		w.WriteHeader(http.StatusNoContent)
		// Cancel the context on request
		cancel()
	})
	go func() {
		if err := s.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[INFO] Faied to start server! %+v", err)
		}
	}()

	select {
	case <-ctx.Done():
		// Shutdown the server when the context is canceled
		s.Shutdown(ctx)
	}
	log.Printf("[INFO] Finished")
}

func main() {
	port := flag.Int("port", 8000, "Port to listen on")
	flag.Parse()
	server(*port)
}

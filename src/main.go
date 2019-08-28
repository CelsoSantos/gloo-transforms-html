package main

import (
	"os"
	"fmt"
	"log"
	"net"
	"strconv"
	"io/ioutil"

	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "github.com/celsosantos/gloo-transforms-html/api"
)

type htmlService struct{}

func (c *htmlService) Render(ctx context.Context, in *pb.HtmlRequest) (*pb.HtmlResponse, error) {
	
	contentBytes, err := ioutil.ReadFile("/var/templates/" + os.Getenv("TEMPLATE") + "-template.html")
	if err != nil {
		log.Println("Error: %s", err)
	}

	htmlTemplate := string(contentBytes)

	return &pb.HtmlResponse{Document: htmlTemplate}, nil
}

func main() {

	port, err := strconv.Atoi(os.Getenv("LISTEN_PORT"))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	// create a listener on TCP port
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	// create a gRPC server object
	grpcServer := grpc.NewServer()

	// create server
	pb.RegisterHtmlServiceServer(grpcServer, &htmlService{})

	//reflection required for Gloo Discovery
	reflection.Register(grpcServer)

	// start the server
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %s", err)
	}
}

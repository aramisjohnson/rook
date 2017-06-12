package main

import (
	"flag"
	"fmt"
	"github.com/rook/rook/e2e/framework/enums"
	"github.com/rook/rook/e2e/framework/manager"
	"github.com/rook/rook/e2e/framework/objects"
	"strings"
)

func main() {
	action := flag.String("action", "", "action to perform for ie. installk8s | installrook | installk8sandrook.")
	flag.Parse()

	env := objects.NewManifest()

	rookPlatform, err := enums.GetRookPlatFormTypeFromString(env.Platform)
	if err != nil {
		panic(fmt.Errorf("Cannot get platform", err))
	}

	k8sVersion, err := enums.GetK8sVersionFromString(env.K8sVersion)
	if err != nil {
		panic(fmt.Errorf("Cannot get k8s version", err))
	}

	err, rookInfra := rook_test_infra.GetRookTestInfraManager(rookPlatform, true, k8sVersion)
	if err != nil {
		panic(fmt.Errorf("Error during Rook Infra Setup", err))
	}

	switch strings.ToLower(*action) {
	case "installk8s":
		rookInfra.ValidateAndSetupTestPlatform(false)

	case "installrook":
		err = rookInfra.InstallRook(env.RookTag, false)

		if err != nil {
			panic(err)
		}
	case "installk8sandrook":
		rookInfra.ValidateAndSetupTestPlatform(false)

		err = rookInfra.InstallRook(env.RookTag, false)

		if err != nil {
			panic(err)
		}
	default:
		flag.Usage()
		panic(fmt.Errorf("'%s' is an unsupported action\n", *action))
	}
}

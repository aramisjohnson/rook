/*
Copyright 2016 The Rook Authors. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package client

import (
	"encoding/json"
	"fmt"
)

func AuthGetKey(conn Connection, name string) (string, error) {
	cmd := map[string]interface{}{"prefix": "auth get-key", "entity": name}
	buf, err := ExecuteMonCommand(conn, cmd, "list pools")
	if err != nil {
		return "", fmt.Errorf("failed to get key for %s: %+v", name, err)
	}

	return parseAuthKey(buf)
}

func AuthGetOrCreateKey(conn Connection, name string, caps []string) (string, error) {
	cmd := map[string]interface{}{
		"prefix": "auth get-or-create-key",
		"entity": name,
		"caps":   caps,
	}
	m := fmt.Sprintf("get or create key for %s", name)
	buf, err := ExecuteMonCommand(conn, cmd, m)
	if err != nil {
		return "", fmt.Errorf("failed to %s: %+v", m, err)
	}

	return parseAuthKey(buf)
}

func AuthDelete(conn Connection, name string) error {
	cmd := map[string]interface{}{"prefix": "auth del", "entity": name}
	_, err := ExecuteMonCommand(conn, cmd, fmt.Sprintf("delete auth for osd %s", name))
	if err != nil {
		return fmt.Errorf("failed to delete auth for %s. %v", name, err)
	}

	return nil
}

func parseAuthKey(buf []byte) (string, error) {
	var resp map[string]interface{}
	if err := json.Unmarshal(buf, &resp); err != nil {
		return "", fmt.Errorf("failed to unmarshal get/create key response: %+v", err)
	}
	return resp["key"].(string), nil
}

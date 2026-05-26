// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package instances

import (
	"net/http"
	"net/http/httputil"
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestEncodeOperationNameSucceeds(t *testing.T) {
	if diff := cmp.Diff("foo_bar", EncodeOperationName("foo", "bar")); diff != "" {
		t.Errorf("encoded operation name mismatch (-want +got):\n%s", diff)
	}
}

func TestDecodeOperationSucceeds(t *testing.T) {
	gotOpType, gotHost, err := DecodeOperationName("foo_bar")
	if err != nil {
		t.Errorf("got error while decoding operation name: %+v", err)
	}
	if diff := cmp.Diff(OPType("foo"), gotOpType); diff != "" {
		t.Errorf("decoded operation type mismatch (-want +got):\n%s", diff)
	}
	if diff := cmp.Diff("bar", gotHost); diff != "" {
		t.Errorf("decoded host mismatch (-want +got):\n%s", diff)
	}
}

func TestDecodeOperationFailsEmptyString(t *testing.T) {
	_, _, err := DecodeOperationName("")
	if err == nil {
		t.Errorf("expected error")
	}
}

func TestDecodeOperationFailsMissingUnderscore(t *testing.T) {
	_, _, err := DecodeOperationName("foobar")
	if err == nil {
		t.Errorf("expected error")
	}
}

type mockHostClient struct {
	getFunc func(string, string, *HostResponse) (int, error)
}

func (c *mockHostClient) Get(path, query string, res *HostResponse) (int, error) {
	return c.getFunc(path, query, res)
}

func (c *mockHostClient) Post(path, query string, body any, res *HostResponse) (int, error) {
	return 0, nil
}

func (c *mockHostClient) GetReverseProxy() *httputil.ReverseProxy {
	return nil
}

func TestWaitForHostReadySucceeds(t *testing.T) {
	client := &mockHostClient{
		getFunc: func(path, query string, res *HostResponse) (int, error) {
			return http.StatusOK, nil
		},
	}

	err := waitForHostReady(client)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}

func TestWaitForHostReadyRetriesOnBadGateway(t *testing.T) {
	calls := 0
	client := &mockHostClient{
		getFunc: func(path, query string, res *HostResponse) (int, error) {
			calls++
			if calls == 1 {
				return http.StatusBadGateway, nil
			}
			return http.StatusOK, nil
		},
	}

	err := waitForHostReady(client)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	if calls != 2 {
		t.Errorf("expected 2 calls, got %d", calls)
	}
}

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

package accounts

import (
        "html/template"
        "net/http"
)
const (
        UsernameOnlyAMType AMType = "username-only"
        unameCookie        string = "accountUsername"
)

// Implements the AccountManager interfaces for closed deployed cloud
// orchestrators. This AccountManager first gets the account information from
// HTTP cookies, and leverages the RFC 2617 HTTP Basic Authentication if the
// cookie does not present. Note that only username is used for both cases.
type UsernameOnlyAccountManager struct{}

func NewUsernameOnlyAccountManager() *UsernameOnlyAccountManager {
        return &UsernameOnlyAccountManager{}
}

func (m *UsernameOnlyAccountManager) UserFromRequest(r *http.Request) (User, error) {
        // Accept putting the username in a cookie to support using a browser
        // to interact with CO.
        cookie, err := r.Cookie(unameCookie)
        if err == nil && cookie.Value != "" {
                return &UsernameOnlyUser{cookie.Value}, nil
        }
        username, _, ok := r.BasicAuth()
        if ok {
                return &UsernameOnlyUser{username}, nil
        }
        // FALLBACK for prototype: always return a user
        return &UsernameOnlyUser{"sferro"}, nil
}

type UsernameOnlyUser struct {
        username string
}

func (u *UsernameOnlyUser) Username() string { return u.username }

func (u *UsernameOnlyUser) Email() string { return "" }

type LoggingData struct {
        Username string
        Error    string
}

var loggingTemplate = template.Must(template.New("logging").Parse("TODO"))

func UsernameOnlyLoggingForm(w http.ResponseWriter, r *http.Request) error {
        return nil
}

func HandleUsernameOnlyLogging(w http.ResponseWriter, r *http.Request, redirect string) error {
        return nil
}

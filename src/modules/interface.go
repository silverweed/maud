package modules

import (
	"net/http"

	. "../data"
)

type Formatter interface {
	Format(string) string
}

type PostMutatorData struct {
	Request        *http.Request
	ResponseWriter *http.ResponseWriter
	Thread         *Thread
	Post           *Post
}

type PostMutator struct {
	Condition func(*http.Request) bool
	Mutator   func(post PostMutatorData)
}

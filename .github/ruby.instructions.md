---
applyTo: "**/*.rb"
---
Ruby Gem Coding Standards

Use this file as a Copilot Instruction: save as .github/copilot-instructions/ruby-gem-standards.md (repo-scoped) or ~/.github/copilot-instructions/ruby-gem-standards.md (global).

These standards define how to design, implement, test, and ship Ruby gems with a clean public API and maintainable internals.

⸻

Philosophy
•	Ruby-first: idiomatic, expressive Ruby. Prefer clarity and readability over ceremony.
•	No static types: Do not add Sorbet/RBS or any type system artifacts. Well-written Ruby and tests are sufficient.
•	Small surface area: keep the public API minimal, stable, and well-documented.
•	Composition over inheritance: favor small objects and collaboration.
•	Predictability: explicit dependencies, clear errors, stable behavior.

⸻

Language & Tooling
•	Ruby version: Support the lowest Ruby your users reasonably need (≥ 3.1 recommended). Add CI matrix across supported Rubies.
•	Strings: Enable # frozen_string_literal: true in all Ruby files.
•	Lint: Use RuboCop (base + Performance). CI must fail on offenses; allow rubocop -A locally.
•	Docs: YARD docstrings on all public classes/modules/methods.
•	Tests: RSpec only. Public API must be fully covered with example-driven specs.
•	Releases: Strict Semantic Versioning (SemVer). Document any deprecations.

⸻

Project Layout (reference)

my_gem/
lib/
my_gem.rb              # top-level namespace & require tree
my_gem/version.rb
my_gem/
errors.rb            # error hierarchy
configuration.rb     # immutable config object
result.rb            # Success/Failure (optional but handy)
adapters/            # external boundaries
services/            # use-cases / operations
models/              # value objects & domain models
internal/            # private helpers (documented as private)
bin/                     # optional executables
spec/
.rubocop.yml
.yardopts
CHANGELOG.md
README.md
my_gem.gemspec


⸻

Public API Design
•	Single entry point: MyGem module exposes configuration and a small set of factories.
•	Keyword args on public methods for clarity and forward-compatibility.
•	Return value objects (immutable) instead of loose hashes; provide #to_h where useful.
•	Avoid raising for expected control flow; prefer Result objects for recoverable outcomes.
•	Document stability with YARD tags: @api public|private|experimental.

Breaking Changes
•	Never change public constant names or keyword names in a minor/patch release.
•	Deprecate first (warn), document alternatives, remove in the next major.

⸻

Configuration
•	Provide a small immutable configuration object.
•	Prefer explicit construction (MyGem.configure { |c| ... } or MyGem::Configuration.new(...)).
•	Accept simple Ruby types; validate eagerly; freeze the instance.

# lib/my_gem/configuration.rb
# frozen_string_literal: true

module MyGem
class Configuration
attr_reader :timeout, :logger

    def initialize(timeout:, logger: nil)
      @timeout = Integer(timeout)
      @logger  = logger
      freeze
    end
end
end


⸻

Errors
•	Define a gem-specific hierarchy; only raise those errors from the public API.
•	Preserve cause: raise MyGem::APIError.new("msg"), cause: e (Ruby ≥ 3.2: raise MyErr, "msg", cause: e).
•	Never rescue Exception; rescue narrow types.

# lib/my_gem/errors.rb
# frozen_string_literal: true

module MyGem
class Error < StandardError; end
class ConfigurationError < Error; end
class TimeoutError < Error; end
class APIError < Error; end
end


⸻

OOP & SOLID (Ruby-idiomatic)
•	Single Responsibility: small classes that do one job.
•	Open/Closed: extend behavior via composition and adapters, not patching.
•	Liskov: define role modules (interfaces-by-duck-typing); keep substitutable behavior.
•	Interface Segregation: many small roles over god objects.
•	Dependency Inversion: depend on role modules; inject concrete collaborators.

# interface role
module MyGem
module Transport
def request(method:, path:, body: nil, headers: {})
raise NotImplementedError
end
end
end

# adapter
class MyGem::FaradayTransport
include MyGem::Transport

def initialize(client:)
@client = client
end

def request(method:, path:, body: nil, headers: {})
@client.public_send(method, path, body, headers)
end
end

# use-case
class MyGem::Services::FetchWidget
def initialize(transport:, config:)
@transport = transport
@config = config
end

def call(id:)
resp = @transport.request(method: :get, path: "/widgets/#{id}")
# parse & return a value object or Result
end
end

Prefer
•	Value Objects (==, eql?, hash, immutability).
•	Command/Service objects with #call.
•	Result objects: Success(value) / Failure(error).
•	Null Objects for optional behavior.
•	Builders for complex construction.

Avoid
•	Monkey-patching core/third-party classes.
•	Global singletons / mutable class-level state.
•	Inheritance-heavy hierarchies; prefer roles + composition.

⸻

Immutability & State
•	Freeze constants, configs, and value objects.
•	No mutable global state; keep state inside instances.
•	If caching, prefer simple memoization per-instance; document thread-safety explicitly.

⸻

Concurrency & Performance
•	Don’t claim thread-safety unless tested.
•	Batch I/O; prefer streaming APIs using Enumerator::Lazy where appropriate.
•	Measure before optimizing; include micro-benchmarks only when needed.

⸻

Logging & Telemetry
•	Accept an optional logger (duck-typed: #debug/#info/#warn/#error).
•	Log operational details at debug level; never secrets.
•	Prefer structured payloads (hashes) at boundaries.

⸻

Dependencies
•	Keep runtime deps minimal; prefer stdlib.
•	Avoid heavy deps (e.g., whole ActiveSupport) unless justified; if used, isolate behind adapters.
•	Use pessimistic constraints (~> x.y) for runtime; pin dev/test tightly.

⸻

Security
•	Validate and sanitize all external inputs.
•	Avoid eval/class_eval on untrusted input.
•	Guard file/network I/O with timeouts and size limits.

⸻

Testing (RSpec)
•	Organize by behavior and public API; avoid testing private methods.
•	Use shared examples to enforce adapter contracts (e.g., Transport).
•	Prefer realistic doubles; keep stubs at interaction boundaries.
•	Include integration specs that exercise the public API as a user would.

# spec/support/shared_examples/transport.rb
RSpec.shared_examples "a transport" do
it "responds to #request with required keywords" do
expect(subject).to respond_to(:request)
expect(subject.method(:request).parameters).to include([:keyreq, :method])
end
end

# spec/my_gem/services/fetch_widget_spec.rb
RSpec.describe MyGem::Services::FetchWidget do
let(:transport) { instance_double(MyGem::Transport, request: { status: 200, body: "{}" }) }
let(:config)    { MyGem::Configuration.new(timeout: 1) }

subject(:service) { described_class.new(transport:, config:) }

it "fetches and returns a value object" do
expect(transport).to receive(:request).with(method: :get, path: "/widgets/123", body: nil, headers: {})
result = service.call(id: 123)
# expect(result).to be_a(MyGem::Models::Widget)
end
end


⸻

Documentation
•	YARD for public API with @param, @return, @raise, @example, and @api tags.
•	README.md includes quickstart, supported Rubies, API highlights.
•	CHANGELOG.md follows Keep a Changelog style.
•	UPGRADING.md for breaking changes.

⸻

CLI (optional)
•	Keep CLI thin; delegate logic to public API.
•	Clear exit codes; idempotent commands; consider --json output.

⸻

Versioning & Release
•	MyGem::VERSION constant; bump with a Rake task.
•	Tagged releases; CI publishes on tags after tests & linters pass.

⸻

Refinements & Monkey Patching
•	No monkey patches in public gems.
•	If you must alter behavior, use Refinements locally and never enable by default; document clearly.

⸻

Namespacing
•	Everything under a single top-level module (MyGem).
•	Internal details live under MyGem::Internal and are documented as private.

⸻

Example Skeleton

# lib/my_gem.rb
# frozen_string_literal: true

require_relative "my_gem/version"
require_relative "my_gem/errors"
require_relative "my_gem/configuration"

module MyGem
class << self
#

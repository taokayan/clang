// RUN: %clang_cc1 %s -triple spir-unknown-unknown -cl-std=c++ -pedantic -verify -fsyntax-only

class A {
  public:
  A() : x(21) {}
  int x;
};

typedef __SIZE_TYPE__ size_t;

class B {
  public:
  B() : bx(42) {}
  void *operator new(size_t);
  void operator delete(void *ptr);
  int bx;
};

// There are no global user-defined new operators at this point. Test that clang
// rejects these gracefully.
void test_default_new_delete(void *buffer, A **pa) {
  A *a = new A;         // expected-error {{'default new' is not supported in OpenCL C++}}
  delete a;             // expected-error {{'default delete' is not supported in OpenCL C++}}
  *pa = new (buffer) A; // expected-error {{'default new' is not supported in OpenCL C++}}
}

// expected-note@+1 {{candidate function not viable: requires 2 arguments, but 1 was provided}}
void *operator new(size_t _s, void *ptr) noexcept {
  return ptr;
}

// expected-note@+1 {{candidate function not viable: requires 2 arguments, but 1 was provided}}
void *operator new[](size_t _s, void *ptr) noexcept {
  return ptr;
}

void test_new_delete(void *buffer, A **a, B **b) {
  *a = new A; // expected-error {{no matching function for call to 'operator new'}}
  delete a;   // expected-error {{'default delete' is not supported in OpenCL C++}}

  *a = new A[20]; // expected-error {{no matching function for call to 'operator new[]'}}
  delete[] *a;    // expected-error {{'default delete' is not supported in OpenCL C++}}

  // User-defined placement new is supported.
  *a = new (buffer) A;

  // User-defined placement new[] is supported.
  *a = new (buffer) A[30];

  // User-defined new is supported.
  *b = new B;

  // User-defined delete is supported.
  delete *b;
}

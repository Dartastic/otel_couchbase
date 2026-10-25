// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_couchbase/otel_couchbase.dart';

/// Traces Couchbase calls with OpenTelemetry.
///
/// `otel_couchbase` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Couchbase call in
/// [tracedCouchbaseKv]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'couchbase-example');

  // Wraps a Couchbase KV op (get/upsert/replace/remove) on a document in a CLIENT span.
  final couchbaseKvId = await tracedCouchbaseKv<String>(
    operation: 'create',
    bucket: 'invoices',
    docId: 'doc_8f3a2c',
    scope: 'example',
    collection: 'orders',
    invoke: () async {
      // Make the Couchbase call here, then report what it returned.
      return 'couchbase_8f3a2c';
    },
  );
  OTelLog.info('tracedCouchbaseKv create returned $couchbaseKvId');

  // Wraps a Couchbase N1QL / SQL++ query in a CLIENT span.
  final couchbaseQueryId = await tracedCouchbaseQuery<String>(
    statement: 'active',
    bucket: 'invoices',
    scope: 'example',
    collection: 'orders',
    consistency: 'example',
    invoke: () async {
      // Make the Couchbase call here, then report what it returned.
      return 'couchbase_8f3a2c';
    },
  );
  OTelLog.info('tracedCouchbaseQuery returned $couchbaseQueryId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCouchbaseInstrumentationAsync.
  await runWithoutCouchbaseInstrumentationAsync(
    () => tracedCouchbaseKv<String>(
      operation: 'create',
      bucket: 'invoices',
      docId: 'doc_8f3a2c',
      scope: 'example',
      collection: 'orders',
      invoke: () async {
        return 'couchbase_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}

# Route 53 Module

Creates DNS records for the edge layer.

Start with simple DNS:

```text
app.example.com -> CloudFront
```

Then upgrade to failover when a secondary region exists:

```text
app.example.com PRIMARY   -> primary CloudFront
app.example.com SECONDARY -> secondary CloudFront
```

CloudFront alias records use hosted zone ID `Z2FDTNDATAQYW2`.

True multi-region failover also requires secondary infrastructure and data replication. DNS failover alone is not a complete disaster recovery strategy.

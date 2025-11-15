# Apple Network Framework Overview

**Source**: https://sosumi.ai/documentation/network
**Fetched**: 2025-11-02

## Overview
Apple's Network framework provides modern APIs for building secure, efficient network applications. It replaces legacy networking approaches with a unified, protocol-agnostic architecture supporting TCP, UDP, TLS, QUIC, and WebSocket protocols.

## Core Concepts
### Endpoints and Connections
The framework uses `NWEndpoint` to represent network destinations, supporting multiple formats: Host-Port connections, Service endpoints, URL endpoints, and Unix domain sockets.

Connections are established through `NWConnection` instances, which manage lifecycle from setup through data transfer to cancellation.

### Parameters and Protocol Stacks
`NWParameters` configures connection behavior, allowing developers to specify transport protocols, security layers, application protocols, path requirements, and privacy settings.

## Connection Management
Connection states include setup, preparing, ready, waiting, failed, and cancelled. The framework provides flexible data transfer methods with buffered receive, message receive, and flexible send capabilities.

## Security Implementation
### TLS Configuration
`NWProtocolTLS.Options` exposes security protocol settings enabling server name indication, certificate validation customization, cipher suite selection, and protocol version constraints.

### Modern Protocols
- **QUIC Support**: HTTP/3 functionality with multiplexed streams, connection migration, and early data
- **WebSocket Support**: RFC 6455 compliance with automatic ping/pong handling

## Path Management
`NWPathMonitor` tracks network availability and characteristics including path status, interface types, and capabilities.

## Service Discovery
- **NWBrowser**: Discovers Bonjour services with result change notifications
- **NWListener**: Creates servers with automatic Bonjour registration

## Advanced Features
- Connection Groups and Multicast
- Ethernet Channel Access
- Custom Protocol Framers
- Metrics and Diagnostics
- Privacy and Attribution

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*

---
layout: post
title: 'OpenStack API Curl Examples'
category: note
slug: openstack-api-curl-examples
---
## Identity: Keystone

### Default-Scoped (May be unscoped)

```bash
$ curl -i -H "Content-Type: application/json" -d '
  { "auth": {
      "identity": {
        "methods": ["password"],
        "password": {
          "user": {
            "name": "admin",
            "domain": { "id": "default" },
            "password": "password"
          }
        }
      }
    }
  }' http://controller:5000/v3/auth/tokens; echo
HTTP/1.1 201 Created
Date: Tue, 18 Dec 2018 08:47:51 GMT
Server: Apache/2.4.18 (Ubuntu)
X-Subject-Token: gAAAAABcGLQ3zJ5fOAr3FJClsDRp9sg-0tHcLcCWr_qCYhbUEdP__3RRWHIPW5MCstltvTDGzL8hOhHClmQpC6jcTPxKZUp-Hk9JkCKRj46oUJ8SvkiPVa0ZVRIjid8sZTKClTsfFzRgBIR5xxH9lzTvUJzQ5T1MxQ
Vary: X-Auth-Token
X-Distribution: Ubuntu
x-openstack-request-id: req-7fcee098-0f81-4896-8a07-e90f0467cf16
Content-Length: 283
Content-Type: application/json

{"token": {"issued_at": "2018-12-18T08:47:51.000000Z", "audit_ids": ["Pj3rp-zmQL6osAyHDfzeAw"], "methods": ["password"], "expires_at": "2018-12-18T09:47:51.000000Z", "user": {"domain": {"id": "default", "name": "Default"}, "id": "e003b3c7d733467b81bb2785cf89cee3", "name": "admin"}}}
```

### Project-Scoped

```bash
$ curl -i -H "Content-Type: application/json" -d '
  { "auth": {
      "identity": {
        "methods": ["password"],
        "password": {
          "user": {
            "name": "admin",
            "domain": { "id": "default" },
            "password": "password"
          }
        }
      },
      "scope": {
        "project": {
          "name": "admin",
          "domain": { "id": "default" }
        }
      }
    }
  }' http://controller:5000/v3/auth/tokens; echo
HTTP/1.1 201 Created
Date: Tue, 18 Dec 2018 09:19:48 GMT
Server: Apache/2.4.18 (Ubuntu)
X-Subject-Token: gAAAAABcGLu1r6d3TxU2VfRV790g9MeRYNoNZYIJFKyJo9zQ-VykuEL32lw52Ya4_xcr6b_avZCHPr4MEj7HL9DHT_L5PXett3FZ3OvphmiZJ3D2quPiO14roBmO289azk8At-yDacZ6Tfh2hdFJ7hZD138jQaG12kJK_6selHaEedLgdOSFG40
Vary: X-Auth-Token
X-Distribution: Ubuntu
x-openstack-request-id: req-7a2635d9-3ddf-4060-bdbe-8fb4132b8100
Content-Length: 5855
Content-Type: application/json

{"token": {"is_domain": false, "methods": ["password"], "roles": [{"id": "9b8a9239c11e4a37b95db1144498bda4", "name": "admin"}], "expires_at": "2018-12-18T10:19:49.000000Z", "project": {"domain": {"id": "default", "name": "Default"}, "id": "242cb8167c0744b9b9bf5da59272a030", "name": "admin"}, "catalog": [{"endpoints": [{"region_id": "RegionOne", "url": "<http://controller:8774/v2.1/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "public", "id": "0f4bc6f4244645319d49d207bf2b3a48"}, {"region_id": "RegionOne", "url": "<http://controller:8774/v2.1/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "internal", "id": "184e8c344cba4d4ba8c5b6d09ab1fb9c"}, {"region_id": "RegionOne", "url": "<http://controller:8774/v2.1/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "admin", "id": "504bd3898bbf40898255ce99734b3887"}], "type": "compute", "id": "3550ae3b1a064e8fac57359f1b003579", "name": "nova"}, {"endpoints": [{"region_id": "RegionOne", "url": "<http://controller:8776/v2/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "admin", "id": "0628c2abf96749adaeb04d36af8a402b"}, {"region_id": "RegionOne", "url": "<http://controller:8776/v2/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "public", "id": "30ecf8d5d7ed47ab875c516d77893913"}, {"region_id": "RegionOne", "url": "<http://controller:8776/v2/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "internal", "id": "d4ea6b20b0b746dbb6670aa8413d8faf"}], "type": "volumev2", "id": "6162341e30014c73b14db19df6207f77", "name": "cinderv2"}, {"endpoints": [{"region_id": "RegionOne", "url": "<http://controller:9292>", "region": "RegionOne", "interface": "admin", "id": "af351c06d9ff4587b0dcf5342b71f227"}, {"region_id": "RegionOne", "url": "<http://controller:9292>", "region": "RegionOne", "interface": "internal", "id": "b3a0c8585d9b4f158ad328a3f46c0eb8"}, {"region_id": "RegionOne", "url": "<http://controller:9292>", "region": "RegionOne", "interface": "public", "id": "dc20cedd6d5a44b5b6b5678777f27118"}], "type": "image", "id": "699f448d9d8344daa8627ec88f1ae90e", "name": "glance"}, {"endpoints": [{"region_id": "RegionOne", "url": "<http://controller:6385>", "region": "RegionOne", "interface": "admin", "id": "491ee653aa2748eca02a026552b55a57"}, {"region_id": "RegionOne", "url": "<http://controller:6385>", "region": "RegionOne", "interface": "public", "id": "c12d29ee0f7c4baab2de0b258229f71f"}, {"region_id": "RegionOne", "url": "<http://controller:6385>", "region": "RegionOne", "interface": "internal", "id": "ef23ec5eab3a46829d43d463b82683d3"}], "type": "baremetal", "id": "7b8d7ff0a80b4dbcb9d026090c8d9d0b", "name": "ironic"}, {"endpoints": [{"region_id": "RegionOne", "url": "<http://controller:35357/v3/>", "region": "RegionOne", "interface": "internal", "id": "152bd59897c348d0a0537adc26696750"}, {"region_id": "RegionOne", "url": "<http://controller:35357/v3/>", "region": "RegionOne", "interface": "admin", "id": "2453a0bcff1042f19a38a17872e0c321"}, {"region_id": "RegionOne", "url": "<http://controller:5000/v3/>", "region": "RegionOne", "interface": "public", "id": "f0c766f8a2404d9286c309221919f100"}], "type": "identity", "id": "86a04dc79dda4375bb5a68e6a7d16237", "name": "keystone"}, {"endpoints": [{"region_id": "RegionOne", "url": "<http://controller:8776/v1/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "internal", "id": "90da85880f9740008779432f47905cca"}, {"region_id": "RegionOne", "url": "<http://controller:8776/v1/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "admin", "id": "9b112975c64c4c67821ff209f6830388"}, {"region_id": "RegionOne", "url": "<http://controller:8776/v1/242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "public", "id": "b79f2c04c73d48fda6b1f02586eaea04"}], "type": "volume", "id": "8b4f915b97db4eedbbe220383b0134ab", "name": "cinder"}, {"endpoints": [{"region_id": "RegionOne", "url": "<http://controller:8080/v1/AUTH_242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "public", "id": "0980fada9919467999acaf23f1a49a7a"}, {"region_id": "RegionOne", "url": "<http://controller:8080/v1>", "region": "RegionOne", "interface": "admin", "id": "30b5a3e793d9419cb0efece77a854487"}, {"region_id": "RegionOne", "url": "<http://controller:8080/v1/AUTH_242cb8167c0744b9b9bf5da59272a030>", "region": "RegionOne", "interface": "internal", "id": "3ddeac64b9e8412ea0c1b3099160f1d9"}], "type": "object-store", "id": "b7b1853b4d0f403fbe221640f03ab9f4", "name": "swift"}, {"endpoints": [{"region_id": "RegionOne", "url": "<http://controller:9696>", "region": "RegionOne", "interface": "public", "id": "3df45f04339c4d069673928cc2957406"}, {"region_id": "RegionOne", "url": "<http://controller:9696>", "region": "RegionOne", "interface": "internal", "id": "68707b9253f24dbf8b838c5d22fa1144"}, {"region_id": "RegionOne", "url": "<http://controller:9696>", "region": "RegionOne", "interface": "admin", "id": "f4376ce0a47b464288ddcb230e65cad1"}], "type": "network", "id": "beb2fc1a4907453c905dac8e35a26df0", "name": "neutron"}, {"endpoints": [{"region_id": "RegionOne", "url": "<http://ironic:5050>", "region": "RegionOne", "interface": "public", "id": "06ff3dae540d462590d7dd1be273554c"}, {"region_id": "RegionOne", "url": "<http://ironic:5050>", "region": "RegionOne", "interface": "internal", "id": "85aa302b9d234959a6ca7d42031c350e"}, {"region_id": "RegionOne", "url": "<http://ironic:5050>", "region": "RegionOne", "interface": "admin", "id": "be29e0142d394478b9def4513afed1a5"}], "type": "baremetal-introspection", "id": "c4926bd176994cf0bc6f30a6415ec0b2", "name": "ironic-inspector"}], "user": {"domain": {"id": "default", "name": "Default"}, "id": "e003b3c7d733467b81bb2785cf89cee3", "name": "admin"}, "audit_ids": ["erPieixLThGVJaIxJw3Cng"], "issued_at": "2018-12-18T09:19:49.000000Z"}}
```

### Domain-Scoped

Get a domain-scoped token (Note that a role-assignment on the domain is needed!):

### Getting A Token from A Token

```bash
$ OS_TOKEN=gAAAAABcGLQ3zJ5fOAr3FJClsDRp9sg-0tHcLcCWr_qCYhbUEdP__3RRWHIPW5MCstltvTDGzL8hOhHClmQpC6jcTPxKZUp-Hk9JkCKRj46oUJ8SvkiPVa0ZVRIjid8sZTKClTsfFzRgBIR5xxH9lzTvUJzQ5T1MxQ
$ curl -i -H "Content-Type: application/json" -d '
  { "auth": {
      "identity": {
        "methods": ["password"],
        "password": {
          "user": {
            "name": "admin",
            "domain": { "id": "default" },
            "password": "password"
          }
        }
      }
    }
  }' http://controller:5000/v3/auth/tokens; echo
HTTP/1.1 201 Created
Date: Tue, 18 Dec 2018 08:52:43 GMT
Server: Apache/2.4.18 (Ubuntu)
X-Subject-Token: gAAAAABcGLVb4w9vpOQITZjJ8Sb4D_L1HFhsJuYCMkck9yau3ZlpLuatk3OCBfHwpq59tMOuJhthz9-OA1nLk-pD969anywIPoo55WKSgxa02gfjLlQyGq8VXZX7X69eqbxTbkKGyDnWEh5z2BunQhipOYXyKnRVFg
Vary: X-Auth-Token
X-Distribution: Ubuntu
x-openstack-request-id: req-ed647da7-5836-41f4-9a5c-cbba52dfb064
Content-Length: 283
Content-Type: application/json

{"token": {"issued_at": "2018-12-18T08:52:43.000000Z", "audit_ids": ["xaSqrWOPRUW3Qy4tiSDklQ"], "methods": ["password"], "expires_at": "2018-12-18T09:52:43.000000Z", "user": {"domain": {"id": "default", "name": "Default"}, "id": "e003b3c7d733467b81bb2785cf89cee3", "name": "admin"}}}
```

If a scope was included in the request body then this would get a token with the new scope.

### User Change Password

Use user's credential to get the token (project-scoped), then change the user's own password.

```bash
$ USER_ID=a6f67ff1136140798a9dad43294d379c
$ ORIG_PASS=password
$ NEW_PASS=123
$ curl -X POST \
  -H "X-Auth-Token: $OS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "user": {"password": "'$NEW_PASS'", "original_password": "'$ORIG_PASS'"} }' \
  http://controller:5000/v3/users/$USER_ID/password
```

### Resetting User Password

Use admin's credential to get the token (project-scoped), then change the target user's password.

```bash
$ USER_ID=a6f67ff1136140798a9dad43294d379c
$ NEW_PASS=newpassword
$ curl -X PATCH \
 -H "X-Auth-Token: $OS_TOKEN" \
 -H "Content-Type: application/json" \
 -d '{ "user": {"password": "'$NEW_PASS'"} }' \
http://controller:5000/v3/users/$USER_ID
```

## References

- [API Examples using Curl - keystone 10.0.3.dev9 documentation](https://docs.openstack.org/keystone/newton/api_curl_examples.html)
- [OpenStack Docs: Identity API v3 (CURRENT)](https://developer.openstack.org/api-ref/identity/v3/index.html)

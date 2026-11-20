{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "70ec7addbf81ecb38af52c4a5f6d5b8f2213a6d2ef6305cbd78b3ce14189ad63",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3349[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[32];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1354 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1361;\n    if (!_1354)\n    {\n        _1361 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1361 = _1354;\n    }\n    bool _1369;\n    if (!_1361)\n    {\n        _1369 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1369 = _1361;\n    }\n    bool _1376;\n    if (!_1369)\n    {\n        _1376 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1376 = _1369;\n    }\n    bool _1383;\n    if (!_1376)\n    {\n        _1383 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    if (_1383)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1393 = vec4(world_pos, 1.0);\n    float _1399 = dot(fa_mesh_fs_params[16], _1393);\n    if (!(_1399 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1421 = vec2(dot(fa_mesh_fs_params[14], _1393), dot(fa_mesh_fs_params[15], _1393)) / vec2(_1399);\n    int _1425 = int(fa_mesh_fs_params[18].x);\n    int _1429 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1429) + clamp(int(floor(((_1421.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1429 - 1)) * _1425)) + clamp(int(floor(((_1421.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1425 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1505 = fa_cluster_texel(param);\n    return ivec2(int(_1505.x), int(_1505.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4142 = fa_cluster_lookup(param);\n    fa_cl_slot = _4142.x;\n    fa_cl_local = _4142.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4505 = fa_linear_to_srgb(param);\n        c = _4505;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4513 = fa_srgb_to_linear(param_1);\n            c = _4513;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _307;\n    if (i.front_facing)\n    {\n        _307 = i.world_normal;\n    }\n    else\n    {\n        _307 = -i.world_normal;\n    }\n    vec3 _331 = normalize(i.world_tangent.xyz - (_307 * dot(_307, i.world_tangent.xyz)));\n    vec3 _359 = normalize(((_331 * m.x) + ((cross(_307, _331) * i.world_tangent.w) * m.y)) + (_307 * m.z));\n    vec3 _362;\n    if (i.front_facing)\n    {\n        _362 = _359;\n    }\n    else\n    {\n        _362 = -_359;\n    }\n    return _362;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4544 = fa_tex_fix(param_2, param_3);\n    vec4 _5638 = base_t;\n    _5638.x = _4544.x;\n    _5638.y = _4544.y;\n    _5638.z = _4544.z;\n    base_t = _5638;\n    vec4 _4558 = (_5638 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5469 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4590 = fa_tex_fix(param_6, param_7);\n        vec3 _4593 = (_4590 * 2.0) - vec3(1.0);\n        vec2 _4598 = _4593.xy * fa_mesh_fs_params[6].x;\n        vec3 _5646 = _4593;\n        _5646.x = _4598.x;\n        _5646.y = _4598.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5646;\n        _5469 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4626 = fa_tex_fix(param_12, param_13);\n    vec4 _5649 = mrt;\n    _5649.x = _4626.x;\n    _5649.y = _4626.y;\n    _5649.z = _4626.z;\n    mrt = _5649;\n    vec4 _4654 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4654.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4665 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4695 = fa_tex_fix(param_20, param_21);\n    float _5474 = fa_mesh_fs_params[20].x;\n    float _5475 = fa_mesh_fs_params[20].y;\n    float _5478 = fa_mesh_fs_params[20].z;\n    float _5477 = fa_mesh_fs_params[21].w;\n    float _5480 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5474 *= _4665.y;\n            _5475 *= _4665.z;\n            _5477 *= _4654.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5478 *= mrt.x;\n            _5480 *= mrt.w;\n        }\n    }\n    return Surface(_4558.xyz, _4558.w, _5469, clamp(fa_mesh_fs_params[5].x * _4626.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4626.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4665.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4695), _5474, _5475, fa_mesh_fs_params[21].xyz, _5477, _5478, fa_mesh_fs_params[20].w, _5480, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1585 = rect.zw - rect.xy;\n    vec2 _1589 = _1585 * atlas;\n    vec2 _1593 = ddx * _1589;\n    vec2 _1597 = ddy * _1589;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1585), clamp(0.5 * log2(max(max(dot(_1593, _1593), dot(_1597, _1597)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1630 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1637;\n    if (!_1630)\n    {\n        _1637 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1637 = _1630;\n    }\n    if (_1637)\n    {\n        return;\n    }\n    vec3 _1643 = dFdx(world_pos);\n    vec3 _1646 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1650 = fa_cluster_texel(param);\n    int _1654 = int(_1650.w);\n    if (_1654 < 1)\n    {\n        return;\n    }\n    int _1664 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1664;\n    vec4 _1668 = fa_light_texel(param_1);\n    vec2 _1671 = _1668.yz;\n    int _1675 = int(_1668.w);\n    int param_2 = _1664 + 1;\n    vec4 _1680 = fa_light_texel(param_2);\n    float _1681 = _1680.x;\n    int _1687 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1691 = int(_1650.z);\n    vec3 _1956;\n    for (int k = 0; k < _1654; k++)\n    {\n        int _1704 = _1691 + k;\n        int param_3 = _1675 + (_1704 >> 2);\n        int _1721 = (_1664 + 2) + (int(fa_light_texel(param_3)[_1704 & 3]) * 7);\n        int param_4 = _1721 + 6;\n        vec4 _1726 = fa_light_texel(param_4);\n        if (((int(_1726.w + 0.5) >> _1687) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1721;\n        vec4 _1741 = fa_light_texel(param_5);\n        int param_6 = _1721 + 1;\n        vec4 _1746 = fa_light_texel(param_6);\n        int param_7 = _1721 + 2;\n        vec4 _1751 = fa_light_texel(param_7);\n        vec3 _1754 = _1741.xyz;\n        float _1759 = dot(_1754, world_pos) + _1741.w;\n        vec3 _1761 = _1746.xyz;\n        float _1766 = dot(_1761, world_pos) + _1746.w;\n        vec3 _1768 = _1751.xyz;\n        float _1773 = dot(_1768, world_pos) + _1751.w;\n        bool _1778 = abs(_1759) > 0.5;\n        bool _1786;\n        if (!_1778)\n        {\n            _1786 = abs(_1766) > 0.5;\n        }\n        else\n        {\n            _1786 = _1778;\n        }\n        bool _1794;\n        if (!_1786)\n        {\n            _1794 = abs(_1773) > 0.5;\n        }\n        else\n        {\n            _1794 = _1786;\n        }\n        if (_1794)\n        {\n            continue;\n        }\n        float _1809 = clamp(dot(geo_normal, normalize(_1768)) * _1726.z, 0.0, 1.0);\n        if (_1809 <= 0.0)\n        {\n            continue;\n        }\n        float _1829 = (clamp((0.5 - abs(_1773)) * 10.0, 0.0, 1.0) * _1809) * _1726.x;\n        vec2 _1837 = vec2(_1759 + 0.5, 0.5 - _1766);\n        vec2 _1847 = vec2(dot(_1754, _1643), dot(_1761, _1643));\n        vec2 _1857 = vec2(dot(_1754, _1646), dot(_1761, _1646));\n        int param_8 = _1721 + 5;\n        vec4 _1862 = fa_light_texel(param_8);\n        int param_9 = _1721 + 3;\n        vec4 _1867 = fa_light_texel(param_9);\n        int param_10 = _1721 + 4;\n        vec4 _1872 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1862.xyz;\n        bool _1882 = _1867.z > _1867.x;\n        if (_1882)\n        {\n            vec4 param_11 = _1867;\n            vec2 param_12 = _1837;\n            vec2 param_13 = _1671;\n            vec2 param_14 = _1847;\n            vec2 param_15 = _1857;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1681 > 0.5) && (_1681 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1908 = fa_dc_to_linear(param_16);\n                vec4 _5557 = tx;\n                _5557.x = _1908.x;\n                _5557.y = _1908.y;\n                _5557.z = _1908.z;\n                tx = _5557;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1829 * tex_a) * _1862.w, 0.0, 1.0)));\n        if (_1872.z > _1872.x)\n        {\n            vec4 param_17 = _1872;\n            vec2 param_18 = _1837;\n            vec2 param_19 = _1671;\n            vec2 param_20 = _1847;\n            vec2 param_21 = _1857;\n            vec4 _1952 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1681 > 1.5)\n            {\n                vec3 param_22 = _1952.xyz;\n                vec3 _1962 = fa_dc_to_srgb(param_22);\n                _1956 = _1962;\n            }\n            else\n            {\n                _1956 = _1952.xyz;\n            }\n            vec3 _1971 = (_1956 * 2.0) - vec3(1.0);\n            vec2 _1976 = _1971.xy * _1726.y;\n            vec3 _1998 = (normalize(_1754) * _1976.x) + (normalize(_1761) * _1976.y);\n            vec3 _2001 = normalize(normal);\n            normal = normalize(mix(_2001, normalize((_2001 * max(_1971.z, 0.0500000007450580596923828125)) + (_1998 - (_2001 * dot(_2001, _1998)))), vec3(clamp(_1829 * (_1882 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _603 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _616 = (c - (ru * hx)) - p;\n        vec3 _622 = ru * (2.0 * hx);\n        float _628 = max(dot(_622, _622), 9.9999999392252902907785028219223e-09);\n        float _632 = dot(_616, _622);\n        float t = clamp((-_632) / _628, 0.0, 1.0);\n        if (_603)\n        {\n            float _647 = dot(r, _622);\n            float _653 = _628 - (_647 * _647);\n            if (abs(_653) > (9.9999997473787516355514526367188e-06 * _628))\n            {\n                t = clamp(((dot(r, _616) * _647) - _632) / _653, 0.0, 1.0);\n            }\n        }\n        return (p + _616) + (_622 * t);\n    }\n    vec3 q = p;\n    float _685 = dot(r, axis);\n    bool _693;\n    if (_603)\n    {\n        _693 = abs(_685) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _693 = _603;\n    }\n    if (_693)\n    {\n        float _703 = dot(c - p, axis) / _685;\n        if (_703 > 0.0)\n        {\n            q = p + (r * _703);\n        }\n    }\n    vec3 _716 = q - c;\n    vec2 xy = vec2(dot(_716, ru), dot(_716, uu));\n    if (shape > 0.5)\n    {\n        float _731 = length(xy);\n        if (_731 > hx)\n        {\n            xy *= (hx / _731);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _523 = dot(d, right);\n    float _527 = dot(d, up);\n    float _538;\n    if (((_523 * _523) + (_527 * _527)) > 1.0000000133514319600180897396058e-10)\n    {\n        _538 = atan(_527, _523) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _538 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_538 - floor(_538)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _374 = abs(d);\n    float _376 = _374.x;\n    float _378 = _374.y;\n    bool _379 = _376 >= _378;\n    bool _387;\n    if (_379)\n    {\n        _387 = _376 >= _374.z;\n    }\n    else\n    {\n        _387 = _379;\n    }\n    int _388;\n    if (_387)\n    {\n        _388 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _403;\n        if (_378 >= _374.z)\n        {\n            _403 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _403 = (d.z > 0.0) ? 4 : 5;\n        }\n        _388 = _403;\n    }\n    return _388;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _769 = fa_light_base(param);\n    bool _773 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _769;\n    vec4 _777 = fa_light_texel(param_1);\n    int param_2 = _769 + 1;\n    vec4 _782 = fa_light_texel(param_2);\n    float _785 = _782.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _797 = _773 && (_785 > 2.5);\n    fa_light_is_area = _797;\n    bool _799 = _785 < 0.5;\n    vec3 l;\n    if (_799)\n    {\n        l = normalize(_777.xyz);\n        if (_773)\n        {\n            int param_3 = _769 + 6;\n            vec4 _813 = fa_light_texel(param_3);\n            if (_813.z > 0.5)\n            {\n                int param_4 = _769 + 4;\n                vec4 _823 = fa_light_texel(param_4);\n                int param_5 = _769 + 5;\n                vec4 _828 = fa_light_texel(param_5);\n                vec2 param_6 = _813.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _823.xyz) * _823.w, (-dot(world_pos, _828.xyz)) * _828.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _858 = _777.xyz;\n        vec3 _860 = _858 - world_pos;\n        vec3 to_light = _860;\n        float _863 = length(_860);\n        float reach = _863;\n        bool front = true;\n        if (_797)\n        {\n            int param_8 = _769 + 7;\n            reach = max(_863 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _769 + 4;\n            vec4 _887 = fa_light_texel(param_9);\n            int param_10 = _769 + 5;\n            vec4 _892 = fa_light_texel(param_10);\n            int param_11 = _769 + 6;\n            vec4 _897 = fa_light_texel(param_11);\n            float _898 = _897.w;\n            int param_12 = _769 + 2;\n            vec3 _905 = normalize(fa_light_texel(param_12).xyz);\n            bool _907 = _898 > 1.5;\n            bool _915;\n            if (!_907)\n            {\n                _915 = dot(_905, to_light) < 0.0;\n            }\n            else\n            {\n                _915 = _907;\n            }\n            front = _915;\n            vec3 r = vec3(0.0);\n            vec3 _924 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _928 = dot(n, n) > 0.5;\n            bool _936;\n            if (_928)\n            {\n                _936 = dot(_924, _924) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _936 = _928;\n            }\n            if (_936)\n            {\n                r = reflect(-normalize(_924), normalize(n));\n            }\n            vec3 param_13 = _858;\n            vec3 param_14 = _905;\n            vec3 param_15 = _887.xyz;\n            vec3 param_16 = _892.xyz;\n            float param_17 = _887.w;\n            float param_18 = _892.w;\n            float param_19 = _898;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _972 = length(to_light);\n        dist = _972;\n        l = to_light / vec3(max(_972, 9.9999997473787516355514526367188e-05));\n        float _986 = reach / max(_777.w, 0.001000000047497451305389404296875);\n        float _992 = clamp(1.0 - (_986 * _986), 0.0, 1.0);\n        float _994;\n        if (front)\n        {\n            _994 = _992 * _992;\n        }\n        else\n        {\n            _994 = 0.0;\n        }\n        atten = _994;\n        bool _1005 = _785 < 2.5;\n        if ((_785 > 1.5) && _1005)\n        {\n            int param_22 = _769 + 2;\n            vec4 _1013 = fa_light_texel(param_22);\n            float _1023 = _1013.w;\n            int param_23 = _769 + 3;\n            vec4 _1028 = fa_light_texel(param_23);\n            float _1029 = _1028.x;\n            float cos_inner = _1029;\n            if (_1029 > 1.5)\n            {\n                cos_inner = mix(_1023, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1023, cos_inner, dot(-l, normalize(_1013.xyz)));\n        }\n        if (_773 && (_785 < 1.5))\n        {\n            int param_24 = _769 + 6;\n            vec4 _1053 = fa_light_texel(param_24);\n            if (_1053.z > 0.5)\n            {\n                vec3 _1061 = -to_light;\n                int param_25 = _769 + 4;\n                int param_26 = _769 + 5;\n                vec3 _1075 = fa_light_texel(param_25).xyz;\n                vec3 _1079 = fa_light_texel(param_26).xyz;\n                vec3 _1088 = vec3(dot(_1061, _1075), dot(_1061, _1079), dot(_1061, cross(_1075, _1079)));\n                vec3 param_27 = _1088;\n                int _1092 = fa_cube_face(param_27);\n                int param_28 = _1092;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1119 = vec2(dot(_1088, cross(param_29, param_30)), dot(_1088, param_30)) / vec2(max(dot(_1088, param_29), 9.9999997473787516355514526367188e-05));\n                int _1123 = _1092 / 3;\n                vec2 param_31 = _1053.xy + (vec2(float(_1092 - (_1123 * 3)), float(_1123)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1119.x), 0.5 - (0.5 * _1119.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _769 + 7;\n            vec4 _1153 = fa_light_texel(param_33);\n            if (_1153.z > 0.5)\n            {\n                int param_34 = _769 + 2;\n                int param_35 = _769 + 4;\n                int param_36 = _769 + 5;\n                vec2 param_37 = _1153.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_773 && _1005)\n            {\n                int param_42 = _769 + 6;\n                vec4 _1200 = fa_light_texel(param_42);\n                int param_43 = _769 + 7;\n                vec4 _1205 = fa_light_texel(param_43);\n                bool _1208 = _1200.z > 0.5;\n                bool _1215;\n                if (!_1208)\n                {\n                    _1215 = _1205.z > 0.5;\n                }\n                else\n                {\n                    _1215 = _1208;\n                }\n                if (_1215)\n                {\n                    int param_44 = _769 + 2;\n                    vec4 _1222 = fa_light_texel(param_44);\n                    vec3 _1226 = normalize(_1222.xyz);\n                    int param_45 = _769 + 4;\n                    vec4 _1231 = fa_light_texel(param_45);\n                    int param_46 = _769 + 5;\n                    vec4 _1236 = fa_light_texel(param_46);\n                    if (_1208)\n                    {\n                        vec3 _1244 = -to_light;\n                        float _1251 = _1222.w;\n                        float _1267 = 0.5 / max(dot(_1244, _1226) * (sqrt(max(1.0 - (_1251 * _1251), 0.0)) / max(_1251, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1200.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1244, _1231.xyz) * _1267), 0.5 - (dot(_1244, _1236.xyz) * _1267));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1205.z > 0.5)\n                    {\n                        vec2 param_49 = _1205.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1226;\n                        vec3 param_52 = _1231.xyz;\n                        vec3 param_53 = _1236.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5294 = _782.xyz * atten;\n    if (_773)\n    {\n        _5294 *= fa_light_tint;\n    }\n    int _1336;\n    if (_799)\n    {\n        _1336 = 0;\n    }\n    else\n    {\n        _1336 = ((_785 > 1.5) && (_785 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5294, atten, 1.0, dist, _1336);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4336 = n < 0;\n    bool _4343;\n    if (!_4336)\n    {\n        _4343 = n >= fa_light_count();\n    }\n    else\n    {\n        _4343 = _4336;\n    }\n    if (_4343)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4351 = fa_cl_light(param);\n    bool _4354 = fa_lm.z > 0.5;\n    bool _4360;\n    if (_4354)\n    {\n        int param_1 = _4351;\n        _4360 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4360 = _4354;\n    }\n    if (_4360)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4351;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4373 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4373;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2130 = fa_shadow_depth(param, param_1);\n    float _2134;\n    if (conv.x < 0.5)\n    {\n        _2134 = _2130;\n    }\n    else\n    {\n        _2134 = (conv.y * conv.z) / (conv.z - (_2130 * (conv.z - conv.y)));\n    }\n    return _2134;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2061 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2061), sin(_2061)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2180 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2189;\n        if (k < 0.0)\n        {\n            _2189 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2189 = k;\n        }\n        float _2209 = clamp((_2189 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2180;\n            vec2 _2228 = fa_shadow_vogel(param_3, param_4, param_5) * _2209;\n            vec2 param_6 = uv + (_2228 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2240 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2240 < (zr - (length(_2228) * plane)))\n            {\n                sum += _2240;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2266 = sum / cnt;\n        float _2276;\n        if (k < 0.0)\n        {\n            _2276 = (-k) / max(_2266, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2276 = k;\n        }\n        radius = clamp(((max(zr - _2266, 0.0) * unit) * _2276) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2298 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2298; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2298;\n        float param_11 = _2180;\n        vec2 _2317 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2317 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2317) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2298);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2517 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2524;\n    if (!_2517)\n    {\n        _2524 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2524 = _2517;\n    }\n    if (_2524)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2537 = fa_light_texel(param);\n    float _2538 = _2537.x;\n    if (_2538 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2547 = int(_2538 + 0.5);\n    int param_1 = _2547;\n    vec4 _2551 = fa_light_texel(param_1);\n    int param_2 = _2547 + 1;\n    vec4 _2556 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2559 = _2551.y;\n    if (_2559 > 0.0)\n    {\n        float _2576 = 1.0 - smoothstep(0.75 * _2559, _2559, length(world - fa_shadows[27].xyz));\n        fade = _2576;\n        if (_2576 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2551.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2600 = (_2547 + 2) + (face * 6);\n    int param_4 = _2600;\n    int param_5 = _2600 + 1;\n    int param_6 = _2600 + 3;\n    vec4 _2614 = fa_light_texel(param_6);\n    int param_7 = _2600 + 4;\n    vec4 _2619 = fa_light_texel(param_7);\n    int param_8 = _2600 + 5;\n    vec4 _2624 = fa_light_texel(param_8);\n    float _2636 = _2624.x * max(dot(_2614, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2641 = clamp(dot(n, l), 0.0, 1.0);\n    float _2664 = clamp(dot(n, _2614.xyz), -1.0, 1.0);\n    float _2683 = min(sqrt(1.0 - (_2664 * _2664)) / max(abs(dot(n, world - lpos)) / max(dot(_2614, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2686 = _2556.y;\n    float _2688;\n    if (_2686 > 0.0)\n    {\n        _2688 = _2686;\n    }\n    else\n    {\n        _2688 = 1.5 * _2636;\n    }\n    vec4 _2708 = vec4(world + (n * (_2688 * sqrt(1.0 - (_2641 * _2641)))), 1.0);\n    float _2712 = dot(_2614, _2708);\n    float _2715 = _2624.y;\n    if (_2712 < _2715)\n    {\n        return 1.0;\n    }\n    vec2 _2730 = vec2(dot(fa_light_texel(param_4), _2708), dot(fa_light_texel(param_5), _2708)) / vec2(_2712);\n    float _2732 = _2730.x;\n    bool _2735 = _2732 < _2619.x;\n    bool _2744;\n    if (!_2735)\n    {\n        _2744 = _2732 > _2619.z;\n    }\n    else\n    {\n        _2744 = _2735;\n    }\n    bool _2753;\n    if (!_2744)\n    {\n        _2753 = _2730.y < _2619.y;\n    }\n    else\n    {\n        _2753 = _2744;\n    }\n    bool _2762;\n    if (!_2753)\n    {\n        _2762 = _2730.y > _2619.w;\n    }\n    else\n    {\n        _2762 = _2753;\n    }\n    if (_2762)\n    {\n        return 1.0;\n    }\n    float _2768 = _2556.x;\n    float _2770;\n    if (_2768 > 0.0)\n    {\n        _2770 = _2768;\n    }\n    else\n    {\n        _2770 = 1.5 * _2636;\n    }\n    vec2 param_9 = _2730;\n    vec4 param_10 = _2619;\n    float param_11 = _2712 - (_2770 * (1.0 + (0.5 * _2683)));\n    float param_12 = _2636;\n    float param_13 = 1.0;\n    float param_14 = _2624.z * 0.25;\n    float param_15 = (_2636 * min(_2683, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2715, _2624.z);\n    int param_17 = int(_2551.z + 0.5);\n    float param_18 = _2551.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2073;\n    if (i == 0)\n    {\n        _2073 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2089;\n        if (i == 1)\n        {\n            _2089 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2097;\n            if (i == 2)\n            {\n                _2097 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2097 = fa_shadows[24].w;\n            }\n            _2089 = _2097;\n        }\n        _2073 = _2089;\n    }\n    return _2073;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2359 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2364 = clamp(dot(n, l), 0.0, 1.0);\n    float _2370 = sqrt(1.0 - (_2364 * _2364));\n    float _2377 = min(_2370 / max(_2364, 0.20000000298023223876953125), 4.0);\n    float _2382;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2382 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2382 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2407 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2382 * _2370)), 1.0);\n    float _2414 = _2407.x;\n    bool _2417 = _2414 < fa_shadows[ci * 1 + 16].x;\n    bool _2426;\n    if (!_2417)\n    {\n        _2426 = _2414 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2426 = _2417;\n    }\n    bool _2435;\n    if (!_2426)\n    {\n        _2435 = _2407.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2435 = _2426;\n    }\n    bool _2444;\n    if (!_2435)\n    {\n        _2444 = _2407.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2444 = _2435;\n    }\n    bool _2451;\n    if (!_2444)\n    {\n        _2451 = _2407.z > 1.0;\n    }\n    else\n    {\n        _2451 = _2444;\n    }\n    if (_2451)\n    {\n        return -1.0;\n    }\n    float _2459;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2459 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2459 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2407.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2407.z - ((_2459 * (1.0 + (0.5 * _2377))) / _2359);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2359;\n    float param_5 = _2359 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2377, 3.0)) * 0.5) / _2359;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2837 = int(fa_shadows[25].x + 0.5);\n    if (_2837 < 1)\n    {\n        return 1.0;\n    }\n    float _2852 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2837 - 1;\n    if (_2852 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2864 = _2837 > 1;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2852 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 1;\n    }\n    bool _2875 = _2837 > 2;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2852 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 2;\n    }\n    bool _2886 = _2837 > 3;\n    bool _2893;\n    if (_2886)\n    {\n        _2893 = _2852 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2893 = _2886;\n    }\n    if (_2893)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2837)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2919 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2919;\n        if (_2919 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2944;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2944 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2944 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2963 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2944, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2974 = clamp((_2852 - (fa_shadow_split_at(param_7) - _2963)) / _2963, 0.0, 1.0);\n        if (_2974 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2837)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2995 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2995;\n                if (_2995 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2974);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3884 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3891;\n    if (!_3884)\n    {\n        _3891 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3891 = _3884;\n    }\n    if (_3891)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3904 = fa_light_texel(param);\n    float _3905 = _3904.y;\n    float len = _3905;\n    if (_3905 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3917 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3927 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3917);\n    if (_3927 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3933 = len;\n    float _3936 = min(_3933, 0.89999997615814208984375 * dist);\n    len = _3936;\n    float _3941 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3917);\n    float _3946 = _3941 + (0.5 * _3936);\n    vec3 _3952 = world + (gn * _3941);\n    float _3954 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4018;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3969 = (float(k) + _3954) * 0.083333335816860198974609375;\n        vec3 _3977 = _3952 + (l * (_3969 * len));\n        vec4 _3983 = vec4(_3977, 1.0);\n        float _3989 = dot(fa_mesh_fs_params[28], _3983);\n        if (_3989 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4009 = vec2(dot(fa_mesh_fs_params[26], _3983), dot(fa_mesh_fs_params[27], _3983)) / vec2(_3989);\n        float _4013 = _4009.x * 0.5;\n        float _4014 = _4013 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4018 = (_4009.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4018 = 0.5 - (_4009.y * 0.5);\n        }\n        bool _4034 = _4014 < 0.0;\n        bool _4041;\n        if (!_4034)\n        {\n            _4041 = _4014 >= 1.0;\n        }\n        else\n        {\n            _4041 = _4034;\n        }\n        bool _4048;\n        if (!_4041)\n        {\n            _4048 = _4018 < 0.0;\n        }\n        else\n        {\n            _4048 = _4041;\n        }\n        bool _4055;\n        if (!_4048)\n        {\n            _4055 = _4018 >= 1.0;\n        }\n        else\n        {\n            _4055 = _4048;\n        }\n        if (_4055)\n        {\n            break;\n        }\n        vec4 _4074 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4014, _4018) * fa_mesh_fs_params[24].zw), 0);\n        if (_4074.w < 0.5)\n        {\n            continue;\n        }\n        float _4093 = (dot(fa_mesh_fs_params[29].xyz, _3977) + fa_mesh_fs_params[29].w) - _4074.x;\n        if ((_4093 > _3941) && (_4093 < _3946))\n        {\n            occ = max(occ, (1.0 - (_3969 * _3969)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4014, 0.5 - _4013), min(_4018, 1.0 - _4018))));\n        }\n    }\n    return 1.0 - (occ * _3927);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4169 = fa_lm.z > 0.5;\n    bool _4175;\n    if (_4169)\n    {\n        int param = li;\n        _4175 = fa_light_baked(param);\n    }\n    else\n    {\n        _4175 = _4169;\n    }\n    if (_4175)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4199 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5440 = _4199.color;\n    float _5442 = _4199.shadow;\n    bool _4202 = _4199.type == 0;\n    if (_4202 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4199.direction;\n        float _4213 = fa_shadow_factor(param_5, param_6);\n        _5442 = _4213;\n        _5440 *= _4213;\n    }\n    else\n    {\n        bool _4224 = _4199.type != 0;\n        bool _4230;\n        if (_4224)\n        {\n            _4230 = _4199.attenuation > 0.0;\n        }\n        else\n        {\n            _4230 = _4224;\n        }\n        if (_4230)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4199.direction;\n            float _4249 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5442 = _4249;\n            _5440 *= _4249;\n        }\n    }\n    bool _4259 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4265;\n    if (_4259)\n    {\n        _4265 = _4199.attenuation > 0.0;\n    }\n    else\n    {\n        _4265 = _4259;\n    }\n    if (_4265)\n    {\n        float _4272;\n        if (_4202)\n        {\n            _4272 = 1000000000.0;\n        }\n        else\n        {\n            _4272 = _4199._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4199.direction;\n        float param_18 = _4272;\n        float _4290 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5442 *= _4290;\n        _5440 *= _4290;\n    }\n    return LightSample(_4199.direction, _5440, _4199.attenuation, _5442, _4199._distance, _4199.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4310 = n < 0;\n    bool _4317;\n    if (!_4310)\n    {\n        _4317 = n >= fa_light_count();\n    }\n    else\n    {\n        _4317 = _4310;\n    }\n    if (_4317)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4332 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4332;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3274 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3282 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3285 = int(_3274);\n    int _3288 = int(_3282);\n    float _3298 = _3282 - float(_3288);\n    int _3354 = (_3285 * 9) + _3288;\n    int _3374 = ((_3285 + 1) * 9) + _3288;\n    return mix(mix(_3349[_3354], _3349[_3354 + 1], _3298), mix(_3349[_3374], _3349[_3374 + 1], _3298), _3274 - float(_3285));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5306 = false;\n    float _5307 = 1.0;\n    float _5308 = 1.0;\n    float _5309 = 1.0;\n    float _5310 = 0.0;\n    float _5311 = 0.0;\n    float _5312 = 0.0;\n    float _5313 = 0.0;\n    float _5315 = 1.0;\n    bool _5316 = false;\n    vec3 _5317 = vec3(0.0);\n    float _5318 = 1.0;\n    float _5319 = 1.0;\n    float _5320 = 1.0;\n    float _5321 = 0.0;\n    float _5322 = 0.0;\n    vec3 _5323 = vec3(1.0, 0.0, 0.0);\n    vec3 _5324 = vec3(0.0, 0.0, 1.0);\n    float _5325 = 1.0;\n    float _5326 = 1.0;\n    float _3425 = clamp(s.specular, 0.0, 1.0);\n    float _3429 = clamp(s.ior, 1.0, 3.0);\n    bool _3434 = (_3425 != 1.0) || (_3429 != 1.5);\n    bool _3443;\n    if (!_3434)\n    {\n        _3443 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3443 = _3434;\n    }\n    if (_3443)\n    {\n        float _3451 = (_3429 - 1.0) / (_3429 + 1.0);\n        f0 = mix(min(vec3(_3451 * _3451) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3425, s.albedo, vec3(metallic));\n        _5307 = mix(_3425, 1.0, metallic);\n        _5306 = true;\n    }\n    float _3478 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3478 > 0.0)\n    {\n        float _3486 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5310 = _3478;\n        _5311 = _3486;\n        float _3493 = _3486 * _3486;\n        _5312 = _3493;\n        _5313 = _3493 * _3493;\n        float _3505 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5315 = _3505;\n        _5308 = 1.0 - (_3478 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3505, 0.0, 1.0), 5.0))));\n        _5306 = true;\n    }\n    vec3 _3525 = max(s.sheen_color, vec3(0.0));\n    float _3534 = max(_3525.x, max(_3525.y, _3525.z));\n    if (_3534 > 0.0)\n    {\n        float _3542 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5316 = true;\n        _5317 = _3525;\n        _5318 = _3542;\n        _5319 = _3542 * _3542;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3542;\n        float _3559 = fa_sheen_albedo(param, param_1);\n        _5321 = _3559;\n        _5320 = 1.0 - min(_3534 * _3559, 1.0);\n        _5306 = true;\n    }\n    _5309 = _5308 * _5320;\n    float _3578 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3578 != 0.0)\n    {\n        vec3 _3593 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3593;\n        if (dot(_3593, _3593) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3605 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3605.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3605.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3605.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3609 = t;\n        vec3 _3610 = normalize(_3609);\n        t = _3610;\n        vec3 _3635 = normalize((_3610 * cos(s.anisotropy_rotation)) + ((cross(n, _3610) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5323 = _3635;\n        _5324 = cross(n, _3635);\n        float _3645 = roughness * roughness;\n        float _3651 = mix(_3645, 1.0, _3578 * _3578);\n        bool _3653 = _3578 > 0.0;\n        _5325 = _3653 ? _3651 : _3645;\n        _5326 = _3653 ? _3645 : _3651;\n        _5322 = _3578;\n        _5306 = true;\n    }\n    return FaLayers(_5306, _5307, _5308, _5309, _5310, _5311, _5312, _5313, i.world_normal, _5315, _5316, _5317, _5318, _5319, _5320, _5321, _5322, _5323, _5324, _5325, _5326);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3206 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3209 = _3206.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3209 * _3209, exp2((-9.27999973297119140625) * ndv)) * _3209) + _3206.y)) + _3206.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3130 = rough * rough;\n    float _3160 = 0.60000002384185791015625 * _3130;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3130)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3160, 0.0500000007450580596923828125 + _3160, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3130 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3686;\n        if (L.aniso >= 0.0)\n        {\n            _3686 = L.b;\n        }\n        else\n        {\n            _3686 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3686, v), _3686), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3719 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3719.x) + (vec3(L.f90) * _3719.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3774 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3774.x) + _3774.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3248 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3248.x) + vec3(_3248.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3813 = clamp(s.metallic, 0.0, 1.0);\n    float _3817 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3824 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3813));\n    vec3 f0 = _3824;\n    vec3 _3828 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3828;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3813;\n    float param_5 = _3817;\n    vec3 param_6 = _3824;\n    FaLayers _3845 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3845.on)\n    {\n        FaLayers param_7 = _3845;\n        vec3 param_8 = _3828;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3817;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3828;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3817;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4393 = fa_light_unshadowed(param, param_1);\n        float _4401 = dot(_4393.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4401 > bestPower)\n        {\n            bestPower = _4401;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4430 = fa_light(param_2, param_3);\n        float _4438;\n        if (dot(s.normal, _4430.direction) > 0.5)\n        {\n            _4438 = 1.0;\n        }\n        else\n        {\n            _4438 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _4430.color) * _4438);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3019 = int(fa_shadows[25].x + 0.5);\n    float _3029 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3034 = _3019 > 0;\n    bool _3043;\n    if (_3034)\n    {\n        int param = _3019 - 1;\n        _3043 = _3029 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3049 = _3019 > 1;\n        bool _3056;\n        if (_3049)\n        {\n            _3056 = _3029 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3056 = _3049;\n        }\n        if (_3056)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3062 = _3019 > 2;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3029 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3075 = _3019 > 3;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3029 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5160 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5160 = -_5160;\n    }\n    vec3 _4831 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5160, fa_world_tangent, fa_uv, fa_vertex_color, _4831, gl_FrontFacing);\n    Surface _4839 = fa_standard_surface(param_1);\n    vec3 _5191 = _4839.albedo;\n    float _5192 = _4839.alpha;\n    vec3 _5193 = _4839.normal;\n    float _5194 = _4839.metallic;\n    float _5195 = _4839.roughness;\n    float _5196 = _4839.occlusion;\n    vec3 _5197 = _4839.emission;\n    float _5198 = _4839.clearcoat;\n    float _5199 = _4839.clearcoat_roughness;\n    vec3 _5200 = _4839.sheen_color;\n    float _5201 = _4839.sheen_roughness;\n    float _5202 = _4839.anisotropy;\n    float _5203 = _4839.anisotropy_rotation;\n    float _5204 = _4839.specular;\n    float _5205 = _4839.ior;\n    vec3 _5206 = _4839.specular_color;\n    float _5207 = _4839.transmission;\n    float _5208 = _4839.thickness;\n    vec3 _5209 = _4839.attenuation_color;\n    float _5210 = _4839.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5160, fa_world_tangent, fa_uv, fa_vertex_color, _4831, gl_FrontFacing);\n    Surface param_3 = _4839;\n    surface(param_2, param_3);\n    _5191 = param_3.albedo;\n    _5192 = param_3.alpha;\n    _5193 = param_3.normal;\n    _5194 = param_3.metallic;\n    _5195 = param_3.roughness;\n    _5196 = param_3.occlusion;\n    _5197 = param_3.emission;\n    _5198 = param_3.clearcoat;\n    _5199 = param_3.clearcoat_roughness;\n    _5200 = param_3.sheen_color;\n    _5201 = param_3.sheen_roughness;\n    _5202 = param_3.anisotropy;\n    _5203 = param_3.anisotropy_rotation;\n    _5204 = param_3.specular;\n    _5205 = param_3.ior;\n    _5206 = param_3.specular_color;\n    _5207 = param_3.transmission;\n    _5208 = param_3.thickness;\n    _5209 = param_3.attenuation_color;\n    _5210 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5160;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5191 = param_6;\n    _5193 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5191;\n    }\n    else\n    {\n        vec3 _4878 = _5193;\n        vec3 _4879 = normalize(_4878);\n        _5193 = _4879;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5160, fa_world_tangent, fa_uv, fa_vertex_color, _4831, gl_FrontFacing);\n        Surface param_9 = Surface(_5191, _5192, _4879, _5194, _5195, _5196, _5197, _5198, _5199, _5200, _5201, _5202, _5203, _5204, _5205, _5206, _5207, _5208, _5209, _5210);\n        vec3 _4890 = lighting(param_8, param_9);\n        result = _4890;\n    }\n    vec3 _4894 = result;\n    vec3 _4895 = _4894 + _5197;\n    result = _4895;\n    vec3 param_10 = _4895;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4904 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4911;\n    if (!_4904)\n    {\n        _4911 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4911 = _4904;\n    }\n    if (_4911)\n    {\n        vec3 _4920 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4926 = dot(_4920, fa_mesh_fs_params[9].xyz);\n        bool _4930 = fa_mesh_fs_params[9].w > 0.5;\n        float _4931;\n        if (_4930)\n        {\n            _4931 = _4926;\n        }\n        else\n        {\n            _4931 = length(_4920);\n        }\n        float _4943 = _4931 - fa_mesh_fs_params[8].x;\n        if (_4943 > 0.0)\n        {\n            float _4952 = fa_mesh_fs_params[7].w * _4943;\n            float tau = _4952 * _4952;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4968;\n                if (_4930)\n                {\n                    _4968 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4926);\n                }\n                else\n                {\n                    _4968 = fa_mesh_fs_params[0].y;\n                }\n                float _4989 = mix(_4968, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4931, 0.0, 1.0));\n                float _4993 = fa_world_pos.y - _4989;\n                float _4998 = _4989 - fa_mesh_fs_params[8].z;\n                float _5003 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5006 = _4998 <= 0.0;\n                bool _5007 = !_5006;\n                bool _5013;\n                if (_5007)\n                {\n                    _5013 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5013 = _5006;\n                }\n                float _5014;\n                if (_5013)\n                {\n                    _5014 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5014 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4998, 80.0));\n                }\n                bool _5041;\n                if (_5007)\n                {\n                    _5041 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5041 = _5006;\n                }\n                float _5042;\n                if (_5041)\n                {\n                    _5042 = fa_mesh_fs_params[8].y * _4998;\n                }\n                else\n                {\n                    _5042 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4998, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5067 = _5003 <= 0.0;\n                bool _5074;\n                if (!_5067)\n                {\n                    _5074 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5074 = _5067;\n                }\n                float _5075;\n                if (_5074)\n                {\n                    _5075 = fa_mesh_fs_params[8].y * _5003;\n                }\n                else\n                {\n                    _5075 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5003, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5102;\n                if (abs(_4993) < 0.001000000047497451305389404296875)\n                {\n                    _5102 = _5014;\n                }\n                else\n                {\n                    _5102 = (_5075 - _5042) / _4993;\n                }\n                tau += (_4943 * max(_5102, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5192);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_425",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2083",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4444",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3349[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[32];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1354 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1361;\n    if (!_1354)\n    {\n        _1361 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1361 = _1354;\n    }\n    bool _1369;\n    if (!_1361)\n    {\n        _1369 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1369 = _1361;\n    }\n    bool _1376;\n    if (!_1369)\n    {\n        _1376 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1376 = _1369;\n    }\n    bool _1383;\n    if (!_1376)\n    {\n        _1383 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    if (_1383)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1393 = vec4(world_pos, 1.0);\n    float _1399 = dot(fa_mesh_fs_params[16], _1393);\n    if (!(_1399 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1421 = vec2(dot(fa_mesh_fs_params[14], _1393), dot(fa_mesh_fs_params[15], _1393)) / vec2(_1399);\n    int _1425 = int(fa_mesh_fs_params[18].x);\n    int _1429 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1429) + clamp(int(floor(((_1421.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1429 - 1)) * _1425)) + clamp(int(floor(((_1421.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1425 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1505 = fa_cluster_texel(param);\n    return ivec2(int(_1505.x), int(_1505.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4142 = fa_cluster_lookup(param);\n    fa_cl_slot = _4142.x;\n    fa_cl_local = _4142.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4505 = fa_linear_to_srgb(param);\n        c = _4505;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4513 = fa_srgb_to_linear(param_1);\n            c = _4513;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _307;\n    if (i.front_facing)\n    {\n        _307 = i.world_normal;\n    }\n    else\n    {\n        _307 = -i.world_normal;\n    }\n    vec3 _331 = normalize(i.world_tangent.xyz - (_307 * dot(_307, i.world_tangent.xyz)));\n    vec3 _359 = normalize(((_331 * m.x) + ((cross(_307, _331) * i.world_tangent.w) * m.y)) + (_307 * m.z));\n    vec3 _362;\n    if (i.front_facing)\n    {\n        _362 = _359;\n    }\n    else\n    {\n        _362 = -_359;\n    }\n    return _362;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4544 = fa_tex_fix(param_2, param_3);\n    vec4 _5638 = base_t;\n    _5638.x = _4544.x;\n    _5638.y = _4544.y;\n    _5638.z = _4544.z;\n    base_t = _5638;\n    vec4 _4558 = (_5638 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5469 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4590 = fa_tex_fix(param_6, param_7);\n        vec3 _4593 = (_4590 * 2.0) - vec3(1.0);\n        vec2 _4598 = _4593.xy * fa_mesh_fs_params[6].x;\n        vec3 _5646 = _4593;\n        _5646.x = _4598.x;\n        _5646.y = _4598.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5646;\n        _5469 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4626 = fa_tex_fix(param_12, param_13);\n    vec4 _5649 = mrt;\n    _5649.x = _4626.x;\n    _5649.y = _4626.y;\n    _5649.z = _4626.z;\n    mrt = _5649;\n    vec4 _4654 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4654.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4665 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4695 = fa_tex_fix(param_20, param_21);\n    float _5474 = fa_mesh_fs_params[20].x;\n    float _5475 = fa_mesh_fs_params[20].y;\n    float _5478 = fa_mesh_fs_params[20].z;\n    float _5477 = fa_mesh_fs_params[21].w;\n    float _5480 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5474 *= _4665.y;\n            _5475 *= _4665.z;\n            _5477 *= _4654.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5478 *= mrt.x;\n            _5480 *= mrt.w;\n        }\n    }\n    return Surface(_4558.xyz, _4558.w, _5469, clamp(fa_mesh_fs_params[5].x * _4626.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4626.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4665.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4695), _5474, _5475, fa_mesh_fs_params[21].xyz, _5477, _5478, fa_mesh_fs_params[20].w, _5480, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1585 = rect.zw - rect.xy;\n    vec2 _1589 = _1585 * atlas;\n    vec2 _1593 = ddx * _1589;\n    vec2 _1597 = ddy * _1589;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1585), clamp(0.5 * log2(max(max(dot(_1593, _1593), dot(_1597, _1597)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1630 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1637;\n    if (!_1630)\n    {\n        _1637 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1637 = _1630;\n    }\n    if (_1637)\n    {\n        return;\n    }\n    vec3 _1643 = dFdx(world_pos);\n    vec3 _1646 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1650 = fa_cluster_texel(param);\n    int _1654 = int(_1650.w);\n    if (_1654 < 1)\n    {\n        return;\n    }\n    int _1664 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1664;\n    vec4 _1668 = fa_light_texel(param_1);\n    vec2 _1671 = _1668.yz;\n    int _1675 = int(_1668.w);\n    int param_2 = _1664 + 1;\n    vec4 _1680 = fa_light_texel(param_2);\n    float _1681 = _1680.x;\n    int _1687 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1691 = int(_1650.z);\n    vec3 _1956;\n    for (int k = 0; k < _1654; k++)\n    {\n        int _1704 = _1691 + k;\n        int param_3 = _1675 + (_1704 >> 2);\n        int _1721 = (_1664 + 2) + (int(fa_light_texel(param_3)[_1704 & 3]) * 7);\n        int param_4 = _1721 + 6;\n        vec4 _1726 = fa_light_texel(param_4);\n        if (((int(_1726.w + 0.5) >> _1687) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1721;\n        vec4 _1741 = fa_light_texel(param_5);\n        int param_6 = _1721 + 1;\n        vec4 _1746 = fa_light_texel(param_6);\n        int param_7 = _1721 + 2;\n        vec4 _1751 = fa_light_texel(param_7);\n        vec3 _1754 = _1741.xyz;\n        float _1759 = dot(_1754, world_pos) + _1741.w;\n        vec3 _1761 = _1746.xyz;\n        float _1766 = dot(_1761, world_pos) + _1746.w;\n        vec3 _1768 = _1751.xyz;\n        float _1773 = dot(_1768, world_pos) + _1751.w;\n        bool _1778 = abs(_1759) > 0.5;\n        bool _1786;\n        if (!_1778)\n        {\n            _1786 = abs(_1766) > 0.5;\n        }\n        else\n        {\n            _1786 = _1778;\n        }\n        bool _1794;\n        if (!_1786)\n        {\n            _1794 = abs(_1773) > 0.5;\n        }\n        else\n        {\n            _1794 = _1786;\n        }\n        if (_1794)\n        {\n            continue;\n        }\n        float _1809 = clamp(dot(geo_normal, normalize(_1768)) * _1726.z, 0.0, 1.0);\n        if (_1809 <= 0.0)\n        {\n            continue;\n        }\n        float _1829 = (clamp((0.5 - abs(_1773)) * 10.0, 0.0, 1.0) * _1809) * _1726.x;\n        vec2 _1837 = vec2(_1759 + 0.5, 0.5 - _1766);\n        vec2 _1847 = vec2(dot(_1754, _1643), dot(_1761, _1643));\n        vec2 _1857 = vec2(dot(_1754, _1646), dot(_1761, _1646));\n        int param_8 = _1721 + 5;\n        vec4 _1862 = fa_light_texel(param_8);\n        int param_9 = _1721 + 3;\n        vec4 _1867 = fa_light_texel(param_9);\n        int param_10 = _1721 + 4;\n        vec4 _1872 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1862.xyz;\n        bool _1882 = _1867.z > _1867.x;\n        if (_1882)\n        {\n            vec4 param_11 = _1867;\n            vec2 param_12 = _1837;\n            vec2 param_13 = _1671;\n            vec2 param_14 = _1847;\n            vec2 param_15 = _1857;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1681 > 0.5) && (_1681 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1908 = fa_dc_to_linear(param_16);\n                vec4 _5557 = tx;\n                _5557.x = _1908.x;\n                _5557.y = _1908.y;\n                _5557.z = _1908.z;\n                tx = _5557;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1829 * tex_a) * _1862.w, 0.0, 1.0)));\n        if (_1872.z > _1872.x)\n        {\n            vec4 param_17 = _1872;\n            vec2 param_18 = _1837;\n            vec2 param_19 = _1671;\n            vec2 param_20 = _1847;\n            vec2 param_21 = _1857;\n            vec4 _1952 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1681 > 1.5)\n            {\n                vec3 param_22 = _1952.xyz;\n                vec3 _1962 = fa_dc_to_srgb(param_22);\n                _1956 = _1962;\n            }\n            else\n            {\n                _1956 = _1952.xyz;\n            }\n            vec3 _1971 = (_1956 * 2.0) - vec3(1.0);\n            vec2 _1976 = _1971.xy * _1726.y;\n            vec3 _1998 = (normalize(_1754) * _1976.x) + (normalize(_1761) * _1976.y);\n            vec3 _2001 = normalize(normal);\n            normal = normalize(mix(_2001, normalize((_2001 * max(_1971.z, 0.0500000007450580596923828125)) + (_1998 - (_2001 * dot(_2001, _1998)))), vec3(clamp(_1829 * (_1882 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _603 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _616 = (c - (ru * hx)) - p;\n        vec3 _622 = ru * (2.0 * hx);\n        float _628 = max(dot(_622, _622), 9.9999999392252902907785028219223e-09);\n        float _632 = dot(_616, _622);\n        float t = clamp((-_632) / _628, 0.0, 1.0);\n        if (_603)\n        {\n            float _647 = dot(r, _622);\n            float _653 = _628 - (_647 * _647);\n            if (abs(_653) > (9.9999997473787516355514526367188e-06 * _628))\n            {\n                t = clamp(((dot(r, _616) * _647) - _632) / _653, 0.0, 1.0);\n            }\n        }\n        return (p + _616) + (_622 * t);\n    }\n    vec3 q = p;\n    float _685 = dot(r, axis);\n    bool _693;\n    if (_603)\n    {\n        _693 = abs(_685) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _693 = _603;\n    }\n    if (_693)\n    {\n        float _703 = dot(c - p, axis) / _685;\n        if (_703 > 0.0)\n        {\n            q = p + (r * _703);\n        }\n    }\n    vec3 _716 = q - c;\n    vec2 xy = vec2(dot(_716, ru), dot(_716, uu));\n    if (shape > 0.5)\n    {\n        float _731 = length(xy);\n        if (_731 > hx)\n        {\n            xy *= (hx / _731);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _523 = dot(d, right);\n    float _527 = dot(d, up);\n    float _538;\n    if (((_523 * _523) + (_527 * _527)) > 1.0000000133514319600180897396058e-10)\n    {\n        _538 = atan(_527, _523) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _538 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_538 - floor(_538)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _374 = abs(d);\n    float _376 = _374.x;\n    float _378 = _374.y;\n    bool _379 = _376 >= _378;\n    bool _387;\n    if (_379)\n    {\n        _387 = _376 >= _374.z;\n    }\n    else\n    {\n        _387 = _379;\n    }\n    int _388;\n    if (_387)\n    {\n        _388 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _403;\n        if (_378 >= _374.z)\n        {\n            _403 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _403 = (d.z > 0.0) ? 4 : 5;\n        }\n        _388 = _403;\n    }\n    return _388;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _769 = fa_light_base(param);\n    bool _773 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _769;\n    vec4 _777 = fa_light_texel(param_1);\n    int param_2 = _769 + 1;\n    vec4 _782 = fa_light_texel(param_2);\n    float _785 = _782.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _797 = _773 && (_785 > 2.5);\n    fa_light_is_area = _797;\n    bool _799 = _785 < 0.5;\n    vec3 l;\n    if (_799)\n    {\n        l = normalize(_777.xyz);\n        if (_773)\n        {\n            int param_3 = _769 + 6;\n            vec4 _813 = fa_light_texel(param_3);\n            if (_813.z > 0.5)\n            {\n                int param_4 = _769 + 4;\n                vec4 _823 = fa_light_texel(param_4);\n                int param_5 = _769 + 5;\n                vec4 _828 = fa_light_texel(param_5);\n                vec2 param_6 = _813.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _823.xyz) * _823.w, (-dot(world_pos, _828.xyz)) * _828.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _858 = _777.xyz;\n        vec3 _860 = _858 - world_pos;\n        vec3 to_light = _860;\n        float _863 = length(_860);\n        float reach = _863;\n        bool front = true;\n        if (_797)\n        {\n            int param_8 = _769 + 7;\n            reach = max(_863 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _769 + 4;\n            vec4 _887 = fa_light_texel(param_9);\n            int param_10 = _769 + 5;\n            vec4 _892 = fa_light_texel(param_10);\n            int param_11 = _769 + 6;\n            vec4 _897 = fa_light_texel(param_11);\n            float _898 = _897.w;\n            int param_12 = _769 + 2;\n            vec3 _905 = normalize(fa_light_texel(param_12).xyz);\n            bool _907 = _898 > 1.5;\n            bool _915;\n            if (!_907)\n            {\n                _915 = dot(_905, to_light) < 0.0;\n            }\n            else\n            {\n                _915 = _907;\n            }\n            front = _915;\n            vec3 r = vec3(0.0);\n            vec3 _924 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _928 = dot(n, n) > 0.5;\n            bool _936;\n            if (_928)\n            {\n                _936 = dot(_924, _924) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _936 = _928;\n            }\n            if (_936)\n            {\n                r = reflect(-normalize(_924), normalize(n));\n            }\n            vec3 param_13 = _858;\n            vec3 param_14 = _905;\n            vec3 param_15 = _887.xyz;\n            vec3 param_16 = _892.xyz;\n            float param_17 = _887.w;\n            float param_18 = _892.w;\n            float param_19 = _898;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _972 = length(to_light);\n        dist = _972;\n        l = to_light / vec3(max(_972, 9.9999997473787516355514526367188e-05));\n        float _986 = reach / max(_777.w, 0.001000000047497451305389404296875);\n        float _992 = clamp(1.0 - (_986 * _986), 0.0, 1.0);\n        float _994;\n        if (front)\n        {\n            _994 = _992 * _992;\n        }\n        else\n        {\n            _994 = 0.0;\n        }\n        atten = _994;\n        bool _1005 = _785 < 2.5;\n        if ((_785 > 1.5) && _1005)\n        {\n            int param_22 = _769 + 2;\n            vec4 _1013 = fa_light_texel(param_22);\n            float _1023 = _1013.w;\n            int param_23 = _769 + 3;\n            vec4 _1028 = fa_light_texel(param_23);\n            float _1029 = _1028.x;\n            float cos_inner = _1029;\n            if (_1029 > 1.5)\n            {\n                cos_inner = mix(_1023, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1023, cos_inner, dot(-l, normalize(_1013.xyz)));\n        }\n        if (_773 && (_785 < 1.5))\n        {\n            int param_24 = _769 + 6;\n            vec4 _1053 = fa_light_texel(param_24);\n            if (_1053.z > 0.5)\n            {\n                vec3 _1061 = -to_light;\n                int param_25 = _769 + 4;\n                int param_26 = _769 + 5;\n                vec3 _1075 = fa_light_texel(param_25).xyz;\n                vec3 _1079 = fa_light_texel(param_26).xyz;\n                vec3 _1088 = vec3(dot(_1061, _1075), dot(_1061, _1079), dot(_1061, cross(_1075, _1079)));\n                vec3 param_27 = _1088;\n                int _1092 = fa_cube_face(param_27);\n                int param_28 = _1092;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1119 = vec2(dot(_1088, cross(param_29, param_30)), dot(_1088, param_30)) / vec2(max(dot(_1088, param_29), 9.9999997473787516355514526367188e-05));\n                int _1123 = _1092 / 3;\n                vec2 param_31 = _1053.xy + (vec2(float(_1092 - (_1123 * 3)), float(_1123)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1119.x), 0.5 - (0.5 * _1119.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _769 + 7;\n            vec4 _1153 = fa_light_texel(param_33);\n            if (_1153.z > 0.5)\n            {\n                int param_34 = _769 + 2;\n                int param_35 = _769 + 4;\n                int param_36 = _769 + 5;\n                vec2 param_37 = _1153.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_773 && _1005)\n            {\n                int param_42 = _769 + 6;\n                vec4 _1200 = fa_light_texel(param_42);\n                int param_43 = _769 + 7;\n                vec4 _1205 = fa_light_texel(param_43);\n                bool _1208 = _1200.z > 0.5;\n                bool _1215;\n                if (!_1208)\n                {\n                    _1215 = _1205.z > 0.5;\n                }\n                else\n                {\n                    _1215 = _1208;\n                }\n                if (_1215)\n                {\n                    int param_44 = _769 + 2;\n                    vec4 _1222 = fa_light_texel(param_44);\n                    vec3 _1226 = normalize(_1222.xyz);\n                    int param_45 = _769 + 4;\n                    vec4 _1231 = fa_light_texel(param_45);\n                    int param_46 = _769 + 5;\n                    vec4 _1236 = fa_light_texel(param_46);\n                    if (_1208)\n                    {\n                        vec3 _1244 = -to_light;\n                        float _1251 = _1222.w;\n                        float _1267 = 0.5 / max(dot(_1244, _1226) * (sqrt(max(1.0 - (_1251 * _1251), 0.0)) / max(_1251, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1200.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1244, _1231.xyz) * _1267), 0.5 - (dot(_1244, _1236.xyz) * _1267));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1205.z > 0.5)\n                    {\n                        vec2 param_49 = _1205.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1226;\n                        vec3 param_52 = _1231.xyz;\n                        vec3 param_53 = _1236.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5294 = _782.xyz * atten;\n    if (_773)\n    {\n        _5294 *= fa_light_tint;\n    }\n    int _1336;\n    if (_799)\n    {\n        _1336 = 0;\n    }\n    else\n    {\n        _1336 = ((_785 > 1.5) && (_785 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5294, atten, 1.0, dist, _1336);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4336 = n < 0;\n    bool _4343;\n    if (!_4336)\n    {\n        _4343 = n >= fa_light_count();\n    }\n    else\n    {\n        _4343 = _4336;\n    }\n    if (_4343)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4351 = fa_cl_light(param);\n    bool _4354 = fa_lm.z > 0.5;\n    bool _4360;\n    if (_4354)\n    {\n        int param_1 = _4351;\n        _4360 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4360 = _4354;\n    }\n    if (_4360)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4351;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4373 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4373;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2130 = fa_shadow_depth(param, param_1);\n    float _2134;\n    if (conv.x < 0.5)\n    {\n        _2134 = _2130;\n    }\n    else\n    {\n        _2134 = (conv.y * conv.z) / (conv.z - (_2130 * (conv.z - conv.y)));\n    }\n    return _2134;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2061 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2061), sin(_2061)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2180 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2189;\n        if (k < 0.0)\n        {\n            _2189 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2189 = k;\n        }\n        float _2209 = clamp((_2189 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2180;\n            vec2 _2228 = fa_shadow_vogel(param_3, param_4, param_5) * _2209;\n            vec2 param_6 = uv + (_2228 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2240 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2240 < (zr - (length(_2228) * plane)))\n            {\n                sum += _2240;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2266 = sum / cnt;\n        float _2276;\n        if (k < 0.0)\n        {\n            _2276 = (-k) / max(_2266, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2276 = k;\n        }\n        radius = clamp(((max(zr - _2266, 0.0) * unit) * _2276) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2298 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2298; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2298;\n        float param_11 = _2180;\n        vec2 _2317 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2317 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2317) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2298);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2517 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2524;\n    if (!_2517)\n    {\n        _2524 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2524 = _2517;\n    }\n    if (_2524)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2537 = fa_light_texel(param);\n    float _2538 = _2537.x;\n    if (_2538 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2547 = int(_2538 + 0.5);\n    int param_1 = _2547;\n    vec4 _2551 = fa_light_texel(param_1);\n    int param_2 = _2547 + 1;\n    vec4 _2556 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2559 = _2551.y;\n    if (_2559 > 0.0)\n    {\n        float _2576 = 1.0 - smoothstep(0.75 * _2559, _2559, length(world - fa_shadows[27].xyz));\n        fade = _2576;\n        if (_2576 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2551.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2600 = (_2547 + 2) + (face * 6);\n    int param_4 = _2600;\n    int param_5 = _2600 + 1;\n    int param_6 = _2600 + 3;\n    vec4 _2614 = fa_light_texel(param_6);\n    int param_7 = _2600 + 4;\n    vec4 _2619 = fa_light_texel(param_7);\n    int param_8 = _2600 + 5;\n    vec4 _2624 = fa_light_texel(param_8);\n    float _2636 = _2624.x * max(dot(_2614, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2641 = clamp(dot(n, l), 0.0, 1.0);\n    float _2664 = clamp(dot(n, _2614.xyz), -1.0, 1.0);\n    float _2683 = min(sqrt(1.0 - (_2664 * _2664)) / max(abs(dot(n, world - lpos)) / max(dot(_2614, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2686 = _2556.y;\n    float _2688;\n    if (_2686 > 0.0)\n    {\n        _2688 = _2686;\n    }\n    else\n    {\n        _2688 = 1.5 * _2636;\n    }\n    vec4 _2708 = vec4(world + (n * (_2688 * sqrt(1.0 - (_2641 * _2641)))), 1.0);\n    float _2712 = dot(_2614, _2708);\n    float _2715 = _2624.y;\n    if (_2712 < _2715)\n    {\n        return 1.0;\n    }\n    vec2 _2730 = vec2(dot(fa_light_texel(param_4), _2708), dot(fa_light_texel(param_5), _2708)) / vec2(_2712);\n    float _2732 = _2730.x;\n    bool _2735 = _2732 < _2619.x;\n    bool _2744;\n    if (!_2735)\n    {\n        _2744 = _2732 > _2619.z;\n    }\n    else\n    {\n        _2744 = _2735;\n    }\n    bool _2753;\n    if (!_2744)\n    {\n        _2753 = _2730.y < _2619.y;\n    }\n    else\n    {\n        _2753 = _2744;\n    }\n    bool _2762;\n    if (!_2753)\n    {\n        _2762 = _2730.y > _2619.w;\n    }\n    else\n    {\n        _2762 = _2753;\n    }\n    if (_2762)\n    {\n        return 1.0;\n    }\n    float _2768 = _2556.x;\n    float _2770;\n    if (_2768 > 0.0)\n    {\n        _2770 = _2768;\n    }\n    else\n    {\n        _2770 = 1.5 * _2636;\n    }\n    vec2 param_9 = _2730;\n    vec4 param_10 = _2619;\n    float param_11 = _2712 - (_2770 * (1.0 + (0.5 * _2683)));\n    float param_12 = _2636;\n    float param_13 = 1.0;\n    float param_14 = _2624.z * 0.25;\n    float param_15 = (_2636 * min(_2683, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2715, _2624.z);\n    int param_17 = int(_2551.z + 0.5);\n    float param_18 = _2551.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2073;\n    if (i == 0)\n    {\n        _2073 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2089;\n        if (i == 1)\n        {\n            _2089 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2097;\n            if (i == 2)\n            {\n                _2097 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2097 = fa_shadows[24].w;\n            }\n            _2089 = _2097;\n        }\n        _2073 = _2089;\n    }\n    return _2073;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2359 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2364 = clamp(dot(n, l), 0.0, 1.0);\n    float _2370 = sqrt(1.0 - (_2364 * _2364));\n    float _2377 = min(_2370 / max(_2364, 0.20000000298023223876953125), 4.0);\n    float _2382;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2382 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2382 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2407 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2382 * _2370)), 1.0);\n    float _2414 = _2407.x;\n    bool _2417 = _2414 < fa_shadows[ci * 1 + 16].x;\n    bool _2426;\n    if (!_2417)\n    {\n        _2426 = _2414 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2426 = _2417;\n    }\n    bool _2435;\n    if (!_2426)\n    {\n        _2435 = _2407.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2435 = _2426;\n    }\n    bool _2444;\n    if (!_2435)\n    {\n        _2444 = _2407.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2444 = _2435;\n    }\n    bool _2451;\n    if (!_2444)\n    {\n        _2451 = _2407.z > 1.0;\n    }\n    else\n    {\n        _2451 = _2444;\n    }\n    if (_2451)\n    {\n        return -1.0;\n    }\n    float _2459;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2459 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2459 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2407.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2407.z - ((_2459 * (1.0 + (0.5 * _2377))) / _2359);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2359;\n    float param_5 = _2359 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2377, 3.0)) * 0.5) / _2359;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2837 = int(fa_shadows[25].x + 0.5);\n    if (_2837 < 1)\n    {\n        return 1.0;\n    }\n    float _2852 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2837 - 1;\n    if (_2852 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2864 = _2837 > 1;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2852 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 1;\n    }\n    bool _2875 = _2837 > 2;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2852 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 2;\n    }\n    bool _2886 = _2837 > 3;\n    bool _2893;\n    if (_2886)\n    {\n        _2893 = _2852 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2893 = _2886;\n    }\n    if (_2893)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2837)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2919 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2919;\n        if (_2919 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2944;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2944 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2944 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2963 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2944, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2974 = clamp((_2852 - (fa_shadow_split_at(param_7) - _2963)) / _2963, 0.0, 1.0);\n        if (_2974 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2837)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2995 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2995;\n                if (_2995 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2974);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3884 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3891;\n    if (!_3884)\n    {\n        _3891 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3891 = _3884;\n    }\n    if (_3891)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3904 = fa_light_texel(param);\n    float _3905 = _3904.y;\n    float len = _3905;\n    if (_3905 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3917 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3927 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3917);\n    if (_3927 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3933 = len;\n    float _3936 = min(_3933, 0.89999997615814208984375 * dist);\n    len = _3936;\n    float _3941 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3917);\n    float _3946 = _3941 + (0.5 * _3936);\n    vec3 _3952 = world + (gn * _3941);\n    float _3954 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4018;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3969 = (float(k) + _3954) * 0.083333335816860198974609375;\n        vec3 _3977 = _3952 + (l * (_3969 * len));\n        vec4 _3983 = vec4(_3977, 1.0);\n        float _3989 = dot(fa_mesh_fs_params[28], _3983);\n        if (_3989 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4009 = vec2(dot(fa_mesh_fs_params[26], _3983), dot(fa_mesh_fs_params[27], _3983)) / vec2(_3989);\n        float _4013 = _4009.x * 0.5;\n        float _4014 = _4013 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4018 = (_4009.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4018 = 0.5 - (_4009.y * 0.5);\n        }\n        bool _4034 = _4014 < 0.0;\n        bool _4041;\n        if (!_4034)\n        {\n            _4041 = _4014 >= 1.0;\n        }\n        else\n        {\n            _4041 = _4034;\n        }\n        bool _4048;\n        if (!_4041)\n        {\n            _4048 = _4018 < 0.0;\n        }\n        else\n        {\n            _4048 = _4041;\n        }\n        bool _4055;\n        if (!_4048)\n        {\n            _4055 = _4018 >= 1.0;\n        }\n        else\n        {\n            _4055 = _4048;\n        }\n        if (_4055)\n        {\n            break;\n        }\n        vec4 _4074 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4014, _4018) * fa_mesh_fs_params[24].zw), 0);\n        if (_4074.w < 0.5)\n        {\n            continue;\n        }\n        float _4093 = (dot(fa_mesh_fs_params[29].xyz, _3977) + fa_mesh_fs_params[29].w) - _4074.x;\n        if ((_4093 > _3941) && (_4093 < _3946))\n        {\n            occ = max(occ, (1.0 - (_3969 * _3969)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4014, 0.5 - _4013), min(_4018, 1.0 - _4018))));\n        }\n    }\n    return 1.0 - (occ * _3927);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4169 = fa_lm.z > 0.5;\n    bool _4175;\n    if (_4169)\n    {\n        int param = li;\n        _4175 = fa_light_baked(param);\n    }\n    else\n    {\n        _4175 = _4169;\n    }\n    if (_4175)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4199 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5440 = _4199.color;\n    float _5442 = _4199.shadow;\n    bool _4202 = _4199.type == 0;\n    if (_4202 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4199.direction;\n        float _4213 = fa_shadow_factor(param_5, param_6);\n        _5442 = _4213;\n        _5440 *= _4213;\n    }\n    else\n    {\n        bool _4224 = _4199.type != 0;\n        bool _4230;\n        if (_4224)\n        {\n            _4230 = _4199.attenuation > 0.0;\n        }\n        else\n        {\n            _4230 = _4224;\n        }\n        if (_4230)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4199.direction;\n            float _4249 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5442 = _4249;\n            _5440 *= _4249;\n        }\n    }\n    bool _4259 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4265;\n    if (_4259)\n    {\n        _4265 = _4199.attenuation > 0.0;\n    }\n    else\n    {\n        _4265 = _4259;\n    }\n    if (_4265)\n    {\n        float _4272;\n        if (_4202)\n        {\n            _4272 = 1000000000.0;\n        }\n        else\n        {\n            _4272 = _4199._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4199.direction;\n        float param_18 = _4272;\n        float _4290 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5442 *= _4290;\n        _5440 *= _4290;\n    }\n    return LightSample(_4199.direction, _5440, _4199.attenuation, _5442, _4199._distance, _4199.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4310 = n < 0;\n    bool _4317;\n    if (!_4310)\n    {\n        _4317 = n >= fa_light_count();\n    }\n    else\n    {\n        _4317 = _4310;\n    }\n    if (_4317)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4332 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4332;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3274 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3282 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3285 = int(_3274);\n    int _3288 = int(_3282);\n    float _3298 = _3282 - float(_3288);\n    int _3354 = (_3285 * 9) + _3288;\n    int _3374 = ((_3285 + 1) * 9) + _3288;\n    return mix(mix(_3349[_3354], _3349[_3354 + 1], _3298), mix(_3349[_3374], _3349[_3374 + 1], _3298), _3274 - float(_3285));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5306 = false;\n    float _5307 = 1.0;\n    float _5308 = 1.0;\n    float _5309 = 1.0;\n    float _5310 = 0.0;\n    float _5311 = 0.0;\n    float _5312 = 0.0;\n    float _5313 = 0.0;\n    float _5315 = 1.0;\n    bool _5316 = false;\n    vec3 _5317 = vec3(0.0);\n    float _5318 = 1.0;\n    float _5319 = 1.0;\n    float _5320 = 1.0;\n    float _5321 = 0.0;\n    float _5322 = 0.0;\n    vec3 _5323 = vec3(1.0, 0.0, 0.0);\n    vec3 _5324 = vec3(0.0, 0.0, 1.0);\n    float _5325 = 1.0;\n    float _5326 = 1.0;\n    float _3425 = clamp(s.specular, 0.0, 1.0);\n    float _3429 = clamp(s.ior, 1.0, 3.0);\n    bool _3434 = (_3425 != 1.0) || (_3429 != 1.5);\n    bool _3443;\n    if (!_3434)\n    {\n        _3443 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3443 = _3434;\n    }\n    if (_3443)\n    {\n        float _3451 = (_3429 - 1.0) / (_3429 + 1.0);\n        f0 = mix(min(vec3(_3451 * _3451) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3425, s.albedo, vec3(metallic));\n        _5307 = mix(_3425, 1.0, metallic);\n        _5306 = true;\n    }\n    float _3478 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3478 > 0.0)\n    {\n        float _3486 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5310 = _3478;\n        _5311 = _3486;\n        float _3493 = _3486 * _3486;\n        _5312 = _3493;\n        _5313 = _3493 * _3493;\n        float _3505 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5315 = _3505;\n        _5308 = 1.0 - (_3478 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3505, 0.0, 1.0), 5.0))));\n        _5306 = true;\n    }\n    vec3 _3525 = max(s.sheen_color, vec3(0.0));\n    float _3534 = max(_3525.x, max(_3525.y, _3525.z));\n    if (_3534 > 0.0)\n    {\n        float _3542 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5316 = true;\n        _5317 = _3525;\n        _5318 = _3542;\n        _5319 = _3542 * _3542;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3542;\n        float _3559 = fa_sheen_albedo(param, param_1);\n        _5321 = _3559;\n        _5320 = 1.0 - min(_3534 * _3559, 1.0);\n        _5306 = true;\n    }\n    _5309 = _5308 * _5320;\n    float _3578 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3578 != 0.0)\n    {\n        vec3 _3593 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3593;\n        if (dot(_3593, _3593) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3605 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3605.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3605.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3605.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3609 = t;\n        vec3 _3610 = normalize(_3609);\n        t = _3610;\n        vec3 _3635 = normalize((_3610 * cos(s.anisotropy_rotation)) + ((cross(n, _3610) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5323 = _3635;\n        _5324 = cross(n, _3635);\n        float _3645 = roughness * roughness;\n        float _3651 = mix(_3645, 1.0, _3578 * _3578);\n        bool _3653 = _3578 > 0.0;\n        _5325 = _3653 ? _3651 : _3645;\n        _5326 = _3653 ? _3645 : _3651;\n        _5322 = _3578;\n        _5306 = true;\n    }\n    return FaLayers(_5306, _5307, _5308, _5309, _5310, _5311, _5312, _5313, i.world_normal, _5315, _5316, _5317, _5318, _5319, _5320, _5321, _5322, _5323, _5324, _5325, _5326);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3206 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3209 = _3206.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3209 * _3209, exp2((-9.27999973297119140625) * ndv)) * _3209) + _3206.y)) + _3206.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3130 = rough * rough;\n    float _3160 = 0.60000002384185791015625 * _3130;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3130)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3160, 0.0500000007450580596923828125 + _3160, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3130 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3686;\n        if (L.aniso >= 0.0)\n        {\n            _3686 = L.b;\n        }\n        else\n        {\n            _3686 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3686, v), _3686), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3719 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3719.x) + (vec3(L.f90) * _3719.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3774 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3774.x) + _3774.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3248 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3248.x) + vec3(_3248.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3813 = clamp(s.metallic, 0.0, 1.0);\n    float _3817 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3824 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3813));\n    vec3 f0 = _3824;\n    vec3 _3828 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3828;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3813;\n    float param_5 = _3817;\n    vec3 param_6 = _3824;\n    FaLayers _3845 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3845.on)\n    {\n        FaLayers param_7 = _3845;\n        vec3 param_8 = _3828;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3817;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3828;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3817;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4393 = fa_light_unshadowed(param, param_1);\n        float _4401 = dot(_4393.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4401 > bestPower)\n        {\n            bestPower = _4401;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4430 = fa_light(param_2, param_3);\n        float _4438;\n        if (dot(s.normal, _4430.direction) > 0.5)\n        {\n            _4438 = 1.0;\n        }\n        else\n        {\n            _4438 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _4430.color) * _4438);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3019 = int(fa_shadows[25].x + 0.5);\n    float _3029 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3034 = _3019 > 0;\n    bool _3043;\n    if (_3034)\n    {\n        int param = _3019 - 1;\n        _3043 = _3029 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3049 = _3019 > 1;\n        bool _3056;\n        if (_3049)\n        {\n            _3056 = _3029 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3056 = _3049;\n        }\n        if (_3056)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3062 = _3019 > 2;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3029 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3075 = _3019 > 3;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3029 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5160 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5160 = -_5160;\n    }\n    vec3 _4831 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5160, fa_world_tangent, fa_uv, fa_vertex_color, _4831, gl_FrontFacing);\n    Surface _4839 = fa_standard_surface(param_1);\n    vec3 _5191 = _4839.albedo;\n    float _5192 = _4839.alpha;\n    vec3 _5193 = _4839.normal;\n    float _5194 = _4839.metallic;\n    float _5195 = _4839.roughness;\n    float _5196 = _4839.occlusion;\n    vec3 _5197 = _4839.emission;\n    float _5198 = _4839.clearcoat;\n    float _5199 = _4839.clearcoat_roughness;\n    vec3 _5200 = _4839.sheen_color;\n    float _5201 = _4839.sheen_roughness;\n    float _5202 = _4839.anisotropy;\n    float _5203 = _4839.anisotropy_rotation;\n    float _5204 = _4839.specular;\n    float _5205 = _4839.ior;\n    vec3 _5206 = _4839.specular_color;\n    float _5207 = _4839.transmission;\n    float _5208 = _4839.thickness;\n    vec3 _5209 = _4839.attenuation_color;\n    float _5210 = _4839.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5160, fa_world_tangent, fa_uv, fa_vertex_color, _4831, gl_FrontFacing);\n    Surface param_3 = _4839;\n    surface(param_2, param_3);\n    _5191 = param_3.albedo;\n    _5192 = param_3.alpha;\n    _5193 = param_3.normal;\n    _5194 = param_3.metallic;\n    _5195 = param_3.roughness;\n    _5196 = param_3.occlusion;\n    _5197 = param_3.emission;\n    _5198 = param_3.clearcoat;\n    _5199 = param_3.clearcoat_roughness;\n    _5200 = param_3.sheen_color;\n    _5201 = param_3.sheen_roughness;\n    _5202 = param_3.anisotropy;\n    _5203 = param_3.anisotropy_rotation;\n    _5204 = param_3.specular;\n    _5205 = param_3.ior;\n    _5206 = param_3.specular_color;\n    _5207 = param_3.transmission;\n    _5208 = param_3.thickness;\n    _5209 = param_3.attenuation_color;\n    _5210 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5160;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5191 = param_6;\n    _5193 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5191;\n    }\n    else\n    {\n        vec3 _4878 = _5193;\n        vec3 _4879 = normalize(_4878);\n        _5193 = _4879;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5160, fa_world_tangent, fa_uv, fa_vertex_color, _4831, gl_FrontFacing);\n        Surface param_9 = Surface(_5191, _5192, _4879, _5194, _5195, _5196, _5197, _5198, _5199, _5200, _5201, _5202, _5203, _5204, _5205, _5206, _5207, _5208, _5209, _5210);\n        vec3 _4890 = lighting(param_8, param_9);\n        result = _4890;\n    }\n    vec3 _4894 = result;\n    vec3 _4895 = _4894 + _5197;\n    result = _4895;\n    vec3 param_10 = _4895;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4904 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4911;\n    if (!_4904)\n    {\n        _4911 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4911 = _4904;\n    }\n    if (_4911)\n    {\n        vec3 _4920 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4926 = dot(_4920, fa_mesh_fs_params[9].xyz);\n        bool _4930 = fa_mesh_fs_params[9].w > 0.5;\n        float _4931;\n        if (_4930)\n        {\n            _4931 = _4926;\n        }\n        else\n        {\n            _4931 = length(_4920);\n        }\n        float _4943 = _4931 - fa_mesh_fs_params[8].x;\n        if (_4943 > 0.0)\n        {\n            float _4952 = fa_mesh_fs_params[7].w * _4943;\n            float tau = _4952 * _4952;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4968;\n                if (_4930)\n                {\n                    _4968 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4926);\n                }\n                else\n                {\n                    _4968 = fa_mesh_fs_params[0].y;\n                }\n                float _4989 = mix(_4968, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4931, 0.0, 1.0));\n                float _4993 = fa_world_pos.y - _4989;\n                float _4998 = _4989 - fa_mesh_fs_params[8].z;\n                float _5003 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5006 = _4998 <= 0.0;\n                bool _5007 = !_5006;\n                bool _5013;\n                if (_5007)\n                {\n                    _5013 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5013 = _5006;\n                }\n                float _5014;\n                if (_5013)\n                {\n                    _5014 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5014 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4998, 80.0));\n                }\n                bool _5041;\n                if (_5007)\n                {\n                    _5041 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5041 = _5006;\n                }\n                float _5042;\n                if (_5041)\n                {\n                    _5042 = fa_mesh_fs_params[8].y * _4998;\n                }\n                else\n                {\n                    _5042 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4998, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5067 = _5003 <= 0.0;\n                bool _5074;\n                if (!_5067)\n                {\n                    _5074 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5074 = _5067;\n                }\n                float _5075;\n                if (_5074)\n                {\n                    _5075 = fa_mesh_fs_params[8].y * _5003;\n                }\n                else\n                {\n                    _5075 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5003, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5102;\n                if (abs(_4993) < 0.001000000047497451305389404296875)\n                {\n                    _5102 = _5014;\n                }\n                else\n                {\n                    _5102 = (_5075 - _5042) / _4993;\n                }\n                tau += (_4943 * max(_5102, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5192);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_425",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2083",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4444",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[32];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _831 = base_t;\n    _831.x = _225.x;\n    _831.y = _225.y;\n    _831.z = _225.z;\n    base_t = _831;\n    vec4 _241 = (_831 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _786 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _839 = _279;\n        _839.x = _284.x;\n        _839.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _842 = mrt;\n    _842.x = _313.x;\n    _842.y = _313.y;\n    _842.z = _313.z;\n    mrt = _842;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _791 = fa_mesh_fs_params[20].x;\n    float _792 = fa_mesh_fs_params[20].y;\n    float _795 = fa_mesh_fs_params[20].z;\n    float _794 = fa_mesh_fs_params[21].w;\n    float _797 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _791 *= _355.y;\n            _792 *= _355.z;\n            _794 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _786, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _791, _792, fa_mesh_fs_params[21].xyz, _794, _795, fa_mesh_fs_params[20].w, _797, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _681 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    vec3 _538 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _538, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _538, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _553 = normalize(param_2.normal);\n    vec3 _568 = normalize(vec3(dot(fa_pre_r0, _553), dot(fa_pre_r1, _553), dot(fa_pre_r2, _553)));\n    float _580 = _568.z;\n    vec2 e = _568.xy / vec2((abs(_568.x) + abs(_568.y)) + abs(_580));\n    if (_580 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[32];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _831 = base_t;\n    _831.x = _225.x;\n    _831.y = _225.y;\n    _831.z = _225.z;\n    base_t = _831;\n    vec4 _241 = (_831 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _786 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _839 = _279;\n        _839.x = _284.x;\n        _839.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _842 = mrt;\n    _842.x = _313.x;\n    _842.y = _313.y;\n    _842.z = _313.z;\n    mrt = _842;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _791 = fa_mesh_fs_params[20].x;\n    float _792 = fa_mesh_fs_params[20].y;\n    float _795 = fa_mesh_fs_params[20].z;\n    float _794 = fa_mesh_fs_params[21].w;\n    float _797 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _791 *= _355.y;\n            _792 *= _355.z;\n            _794 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _786, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _791, _792, fa_mesh_fs_params[21].xyz, _794, _795, fa_mesh_fs_params[20].w, _797, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _681 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    vec3 _538 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _538, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _538, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _553 = normalize(param_2.normal);\n    vec3 _568 = normalize(vec3(dot(fa_pre_r0, _553), dot(fa_pre_r1, _553), dot(fa_pre_r2, _553)));\n    float _580 = _568.z;\n    vec2 e = _568.xy / vec2((abs(_568.x) + abs(_568.y)) + abs(_580));\n    if (_580 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    }
  }
}

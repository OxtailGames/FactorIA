{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3516[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1357 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1372;\n    if (!_1364)\n    {\n        _1372 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1372 = _1364;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    bool _1386;\n    if (!_1379)\n    {\n        _1386 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1386 = _1379;\n    }\n    if (_1386)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1396 = vec4(world_pos, 1.0);\n    float _1402 = dot(fa_mesh_fs_params[16], _1396);\n    if (!(_1402 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1424 = vec2(dot(fa_mesh_fs_params[14], _1396), dot(fa_mesh_fs_params[15], _1396)) / vec2(_1402);\n    int _1428 = int(fa_mesh_fs_params[18].x);\n    int _1432 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1432) + clamp(int(floor(((_1424.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1432 - 1)) * _1428)) + clamp(int(floor(((_1424.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1428 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1508 = fa_cluster_texel(param);\n    return ivec2(int(_1508.x), int(_1508.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4046 = fa_cluster_lookup(param);\n    fa_cl_slot = _4046.x;\n    fa_cl_local = _4046.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4209 = fa_linear_to_srgb(param);\n        c = _4209;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4217 = fa_srgb_to_linear(param_1);\n            c = _4217;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _312;\n    if (i.front_facing)\n    {\n        _312 = i.world_normal;\n    }\n    else\n    {\n        _312 = -i.world_normal;\n    }\n    vec3 _336 = normalize(i.world_tangent.xyz - (_312 * dot(_312, i.world_tangent.xyz)));\n    vec3 _363 = normalize(((_336 * m.x) + ((cross(_312, _336) * i.world_tangent.w) * m.y)) + (_312 * m.z));\n    vec3 _366;\n    if (i.front_facing)\n    {\n        _366 = _363;\n    }\n    else\n    {\n        _366 = -_363;\n    }\n    return _366;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4248 = fa_tex_fix(param_2, param_3);\n    vec4 _5363 = base_t;\n    _5363.x = _4248.x;\n    _5363.y = _4248.y;\n    _5363.z = _4248.z;\n    base_t = _5363;\n    vec4 _4262 = (_5363 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5215 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4294 = fa_tex_fix(param_6, param_7);\n        vec3 _4297 = (_4294 * 2.0) - vec3(1.0);\n        vec2 _4302 = _4297.xy * fa_mesh_fs_params[6].x;\n        vec3 _5371 = _4297;\n        _5371.x = _4302.x;\n        _5371.y = _4302.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5371;\n        _5215 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4330 = fa_tex_fix(param_12, param_13);\n    vec4 _5374 = mrt;\n    _5374.x = _4330.x;\n    _5374.y = _4330.y;\n    _5374.z = _4330.z;\n    mrt = _5374;\n    vec4 _4358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4369 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4399 = fa_tex_fix(param_20, param_21);\n    float _5220 = fa_mesh_fs_params[20].x;\n    float _5221 = fa_mesh_fs_params[20].y;\n    float _5224 = fa_mesh_fs_params[20].z;\n    float _5223 = fa_mesh_fs_params[21].w;\n    float _5226 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5220 *= _4369.y;\n            _5221 *= _4369.z;\n            _5223 *= _4358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5224 *= mrt.x;\n            _5226 *= mrt.w;\n        }\n    }\n    return Surface(_4262.xyz, _4262.w, _5215, clamp(fa_mesh_fs_params[5].x * _4330.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4330.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4369.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4399), _5220, _5221, fa_mesh_fs_params[21].xyz, _5223, _5224, fa_mesh_fs_params[20].w, _5226, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1588 = rect.zw - rect.xy;\n    vec2 _1592 = _1588 * atlas;\n    vec2 _1596 = ddx * _1592;\n    vec2 _1600 = ddy * _1592;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1588), clamp(0.5 * log2(max(max(dot(_1596, _1596), dot(_1600, _1600)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1633 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return;\n    }\n    vec3 _1646 = dFdx(world_pos);\n    vec3 _1649 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1653 = fa_cluster_texel(param);\n    int _1657 = int(_1653.w);\n    if (_1657 < 1)\n    {\n        return;\n    }\n    int _1667 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1667;\n    vec4 _1671 = fa_light_texel(param_1);\n    vec2 _1674 = _1671.yz;\n    int _1678 = int(_1671.w);\n    int param_2 = _1667 + 1;\n    vec4 _1683 = fa_light_texel(param_2);\n    float _1684 = _1683.x;\n    int _1690 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1694 = int(_1653.z);\n    vec3 _1959;\n    for (int k = 0; k < _1657; k++)\n    {\n        int _1707 = _1694 + k;\n        int param_3 = _1678 + (_1707 >> 2);\n        int _1724 = (_1667 + 2) + (int(fa_light_texel(param_3)[_1707 & 3]) * 7);\n        int param_4 = _1724 + 6;\n        vec4 _1729 = fa_light_texel(param_4);\n        if (((int(_1729.w + 0.5) >> _1690) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1724;\n        vec4 _1744 = fa_light_texel(param_5);\n        int param_6 = _1724 + 1;\n        vec4 _1749 = fa_light_texel(param_6);\n        int param_7 = _1724 + 2;\n        vec4 _1754 = fa_light_texel(param_7);\n        vec3 _1757 = _1744.xyz;\n        float _1762 = dot(_1757, world_pos) + _1744.w;\n        vec3 _1764 = _1749.xyz;\n        float _1769 = dot(_1764, world_pos) + _1749.w;\n        vec3 _1771 = _1754.xyz;\n        float _1776 = dot(_1771, world_pos) + _1754.w;\n        bool _1781 = abs(_1762) > 0.5;\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1769) > 0.5;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1776) > 0.5;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        if (_1797)\n        {\n            continue;\n        }\n        float _1812 = clamp(dot(geo_normal, normalize(_1771)) * _1729.z, 0.0, 1.0);\n        if (_1812 <= 0.0)\n        {\n            continue;\n        }\n        float _1832 = (clamp((0.5 - abs(_1776)) * 10.0, 0.0, 1.0) * _1812) * _1729.x;\n        vec2 _1840 = vec2(_1762 + 0.5, 0.5 - _1769);\n        vec2 _1850 = vec2(dot(_1757, _1646), dot(_1764, _1646));\n        vec2 _1860 = vec2(dot(_1757, _1649), dot(_1764, _1649));\n        int param_8 = _1724 + 5;\n        vec4 _1865 = fa_light_texel(param_8);\n        int param_9 = _1724 + 3;\n        vec4 _1870 = fa_light_texel(param_9);\n        int param_10 = _1724 + 4;\n        vec4 _1875 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1865.xyz;\n        bool _1885 = _1870.z > _1870.x;\n        if (_1885)\n        {\n            vec4 param_11 = _1870;\n            vec2 param_12 = _1840;\n            vec2 param_13 = _1674;\n            vec2 param_14 = _1850;\n            vec2 param_15 = _1860;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1684 > 0.5) && (_1684 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1911 = fa_dc_to_linear(param_16);\n                vec4 _5295 = tx;\n                _5295.x = _1911.x;\n                _5295.y = _1911.y;\n                _5295.z = _1911.z;\n                tx = _5295;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1832 * tex_a) * _1865.w, 0.0, 1.0)));\n        if (_1875.z > _1875.x)\n        {\n            vec4 param_17 = _1875;\n            vec2 param_18 = _1840;\n            vec2 param_19 = _1674;\n            vec2 param_20 = _1850;\n            vec2 param_21 = _1860;\n            vec4 _1955 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1684 > 1.5)\n            {\n                vec3 param_22 = _1955.xyz;\n                vec3 _1965 = fa_dc_to_srgb(param_22);\n                _1959 = _1965;\n            }\n            else\n            {\n                _1959 = _1955.xyz;\n            }\n            vec3 _1974 = (_1959 * 2.0) - vec3(1.0);\n            vec2 _1979 = _1974.xy * _1729.y;\n            vec3 _2001 = (normalize(_1757) * _1979.x) + (normalize(_1764) * _1979.y);\n            vec3 _2004 = normalize(normal);\n            normal = normalize(mix(_2004, normalize((_2004 * max(_1974.z, 0.0500000007450580596923828125)) + (_2001 - (_2004 * dot(_2004, _2001)))), vec3(clamp(_1832 * (_1885 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3199 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3199;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3442 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3449 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3452 = int(_3442);\n    int _3455 = int(_3449);\n    float _3465 = _3449 - float(_3455);\n    int _3520 = (_3452 * 9) + _3455;\n    int _3540 = ((_3452 + 1) * 9) + _3455;\n    return mix(mix(_3516[_3520], _3516[_3520 + 1], _3465), mix(_3516[_3540], _3516[_3540 + 1], _3465), _3442 - float(_3452));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5074 = false;\n    float _5075 = 1.0;\n    float _5076 = 1.0;\n    float _5077 = 1.0;\n    float _5078 = 0.0;\n    float _5079 = 0.0;\n    float _5080 = 0.0;\n    float _5081 = 0.0;\n    float _5083 = 1.0;\n    bool _5084 = false;\n    vec3 _5085 = vec3(0.0);\n    float _5086 = 1.0;\n    float _5087 = 1.0;\n    float _5088 = 1.0;\n    float _5089 = 0.0;\n    float _5090 = 0.0;\n    vec3 _5091 = vec3(1.0, 0.0, 0.0);\n    vec3 _5092 = vec3(0.0, 0.0, 1.0);\n    float _5093 = 1.0;\n    float _5094 = 1.0;\n    float _3591 = clamp(s.specular, 0.0, 1.0);\n    float _3595 = clamp(s.ior, 1.0, 3.0);\n    bool _3600 = (_3591 != 1.0) || (_3595 != 1.5);\n    bool _3609;\n    if (!_3600)\n    {\n        _3609 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3609 = _3600;\n    }\n    if (_3609)\n    {\n        float _3617 = (_3595 - 1.0) / (_3595 + 1.0);\n        f0 = mix(min(vec3(_3617 * _3617) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3591, s.albedo, vec3(metallic));\n        _5075 = mix(_3591, 1.0, metallic);\n        _5074 = true;\n    }\n    float _3644 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3644 > 0.0)\n    {\n        float _3652 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5078 = _3644;\n        _5079 = _3652;\n        float _3659 = _3652 * _3652;\n        _5080 = _3659;\n        _5081 = _3659 * _3659;\n        float _3671 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5083 = _3671;\n        _5076 = 1.0 - (_3644 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3671, 0.0, 1.0), 5.0))));\n        _5074 = true;\n    }\n    vec3 _3690 = max(s.sheen_color, vec3(0.0));\n    float _3699 = max(_3690.x, max(_3690.y, _3690.z));\n    if (_3699 > 0.0)\n    {\n        float _3707 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5084 = true;\n        _5085 = _3690;\n        _5086 = _3707;\n        _5087 = _3707 * _3707;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3707;\n        float _3724 = fa_sheen_albedo(param, param_1);\n        _5089 = _3724;\n        _5088 = 1.0 - min(_3699 * _3724, 1.0);\n        _5074 = true;\n    }\n    _5077 = _5076 * _5088;\n    float _3743 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3743 != 0.0)\n    {\n        vec3 _3758 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3758;\n        if (dot(_3758, _3758) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3770 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3770.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3770.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3770.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3774 = t;\n        vec3 _3775 = normalize(_3774);\n        t = _3775;\n        vec3 _3800 = normalize((_3775 * cos(s.anisotropy_rotation)) + ((cross(n, _3775) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5091 = _3800;\n        _5092 = cross(n, _3800);\n        float _3810 = roughness * roughness;\n        float _3816 = mix(_3810, 1.0, _3743 * _3743);\n        bool _3818 = _3743 > 0.0;\n        _5093 = _3818 ? _3816 : _3810;\n        _5094 = _3818 ? _3810 : _3816;\n        _5090 = _3743;\n        _5074 = true;\n    }\n    return FaLayers(_5074, _5075, _5076, _5077, _5078, _5079, _5080, _5081, i.world_normal, _5083, _5084, _5085, _5086, _5087, _5088, _5089, _5090, _5091, _5092, _5093, _5094);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3374 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3377 = _3374.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3377 * _3377, exp2((-9.27999973297119140625) * ndv)) * _3377) + _3374.y)) + _3374.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3228 = rough * rough;\n    float _3258 = 0.60000002384185791015625 * _3228;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3228)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3258, 0.0500000007450580596923828125 + _3258, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3228 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3851;\n        if (L.aniso >= 0.0)\n        {\n            _3851 = L.b;\n        }\n        else\n        {\n            _3851 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3851, v), _3851), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3884 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3884.x) + (vec3(L.f90) * _3884.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3939 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3939.x) + _3939.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3416 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3416.x) + vec3(_3416.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3968 = clamp(s.metallic, 0.0, 1.0);\n    float _3972 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3979 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3968));\n    vec3 f0 = _3979;\n    vec3 _3983 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3983;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3968;\n    float param_5 = _3972;\n    vec3 param_6 = _3979;\n    FaLayers _4000 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4000.on)\n    {\n        FaLayers param_7 = _4000;\n        vec3 param_8 = _3983;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3972;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3983;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3972;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _607 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _620 = (c - (ru * hx)) - p;\n        vec3 _626 = ru * (2.0 * hx);\n        float _632 = max(dot(_626, _626), 9.9999999392252902907785028219223e-09);\n        float _636 = dot(_620, _626);\n        float t = clamp((-_636) / _632, 0.0, 1.0);\n        if (_607)\n        {\n            float _651 = dot(r, _626);\n            float _657 = _632 - (_651 * _651);\n            if (abs(_657) > (9.9999997473787516355514526367188e-06 * _632))\n            {\n                t = clamp(((dot(r, _620) * _651) - _636) / _657, 0.0, 1.0);\n            }\n        }\n        return (p + _620) + (_626 * t);\n    }\n    vec3 q = p;\n    float _689 = dot(r, axis);\n    bool _697;\n    if (_607)\n    {\n        _697 = abs(_689) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _697 = _607;\n    }\n    if (_697)\n    {\n        float _707 = dot(c - p, axis) / _689;\n        if (_707 > 0.0)\n        {\n            q = p + (r * _707);\n        }\n    }\n    vec3 _720 = q - c;\n    vec2 xy = vec2(dot(_720, ru), dot(_720, uu));\n    if (shape > 0.5)\n    {\n        float _735 = length(xy);\n        if (_735 > hx)\n        {\n            xy *= (hx / _735);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _378 = abs(d);\n    float _380 = _378.x;\n    float _382 = _378.y;\n    bool _383 = _380 >= _382;\n    bool _391;\n    if (_383)\n    {\n        _391 = _380 >= _378.z;\n    }\n    else\n    {\n        _391 = _383;\n    }\n    int _392;\n    if (_391)\n    {\n        _392 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _407;\n        if (_382 >= _378.z)\n        {\n            _407 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _407 = (d.z > 0.0) ? 4 : 5;\n        }\n        _392 = _407;\n    }\n    return _392;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _527 = dot(d, right);\n    float _531 = dot(d, up);\n    float _542;\n    if (((_527 * _527) + (_531 * _531)) > 1.0000000133514319600180897396058e-10)\n    {\n        _542 = atan(_531, _527) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _542 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_542 - floor(_542)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _773 = fa_light_base(param);\n    bool _777 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _773;\n    vec4 _781 = fa_light_texel(param_1);\n    int param_2 = _773 + 1;\n    vec4 _786 = fa_light_texel(param_2);\n    float _789 = _786.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _801 = _777 && (_789 > 2.5);\n    fa_light_is_area = _801;\n    bool _803 = _789 < 0.5;\n    vec3 l;\n    if (_803)\n    {\n        l = normalize(_781.xyz);\n        if (_777)\n        {\n            int param_3 = _773 + 6;\n            vec4 _817 = fa_light_texel(param_3);\n            if (_817.z > 0.5)\n            {\n                int param_4 = _773 + 4;\n                vec4 _827 = fa_light_texel(param_4);\n                int param_5 = _773 + 5;\n                vec4 _832 = fa_light_texel(param_5);\n                vec2 param_6 = _817.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _827.xyz) * _827.w, (-dot(world_pos, _832.xyz)) * _832.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _862 = _781.xyz;\n        vec3 _864 = _862 - world_pos;\n        vec3 to_light = _864;\n        float _867 = length(_864);\n        float reach = _867;\n        bool front = true;\n        if (_801)\n        {\n            int param_8 = _773 + 7;\n            reach = max(_867 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _773 + 4;\n            vec4 _891 = fa_light_texel(param_9);\n            int param_10 = _773 + 5;\n            vec4 _896 = fa_light_texel(param_10);\n            int param_11 = _773 + 6;\n            vec4 _901 = fa_light_texel(param_11);\n            float _902 = _901.w;\n            int param_12 = _773 + 2;\n            vec3 _909 = normalize(fa_light_texel(param_12).xyz);\n            bool _911 = _902 > 1.5;\n            bool _919;\n            if (!_911)\n            {\n                _919 = dot(_909, to_light) < 0.0;\n            }\n            else\n            {\n                _919 = _911;\n            }\n            front = _919;\n            vec3 r = vec3(0.0);\n            vec3 _928 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _932 = dot(n, n) > 0.5;\n            bool _940;\n            if (_932)\n            {\n                _940 = dot(_928, _928) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _940 = _932;\n            }\n            if (_940)\n            {\n                r = reflect(-normalize(_928), normalize(n));\n            }\n            vec3 param_13 = _862;\n            vec3 param_14 = _909;\n            vec3 param_15 = _891.xyz;\n            vec3 param_16 = _896.xyz;\n            float param_17 = _891.w;\n            float param_18 = _896.w;\n            float param_19 = _902;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _976 = length(to_light);\n        dist = _976;\n        l = to_light / vec3(max(_976, 9.9999997473787516355514526367188e-05));\n        float _990 = reach / max(_781.w, 0.001000000047497451305389404296875);\n        float _996 = clamp(1.0 - (_990 * _990), 0.0, 1.0);\n        float _998;\n        if (front)\n        {\n            _998 = _996 * _996;\n        }\n        else\n        {\n            _998 = 0.0;\n        }\n        atten = _998;\n        bool _1009 = _789 < 2.5;\n        if ((_789 > 1.5) && _1009)\n        {\n            int param_22 = _773 + 2;\n            vec4 _1017 = fa_light_texel(param_22);\n            float _1027 = _1017.w;\n            int param_23 = _773 + 3;\n            vec4 _1032 = fa_light_texel(param_23);\n            float _1033 = _1032.x;\n            float cos_inner = _1033;\n            if (_1033 > 1.5)\n            {\n                cos_inner = mix(_1027, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1027, cos_inner, dot(-l, normalize(_1017.xyz)));\n        }\n        if (_777 && (_789 < 1.5))\n        {\n            int param_24 = _773 + 6;\n            vec4 _1057 = fa_light_texel(param_24);\n            if (_1057.z > 0.5)\n            {\n                vec3 _1065 = -to_light;\n                int param_25 = _773 + 4;\n                int param_26 = _773 + 5;\n                vec3 _1079 = fa_light_texel(param_25).xyz;\n                vec3 _1083 = fa_light_texel(param_26).xyz;\n                vec3 _1092 = vec3(dot(_1065, _1079), dot(_1065, _1083), dot(_1065, cross(_1079, _1083)));\n                vec3 param_27 = _1092;\n                int _1096 = fa_cube_face(param_27);\n                int param_28 = _1096;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1123 = vec2(dot(_1092, cross(param_29, param_30)), dot(_1092, param_30)) / vec2(max(dot(_1092, param_29), 9.9999997473787516355514526367188e-05));\n                int _1127 = _1096 / 3;\n                vec2 param_31 = _1057.xy + (vec2(float(_1096 - (_1127 * 3)), float(_1127)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1123.x), 0.5 - (0.5 * _1123.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _773 + 7;\n            vec4 _1157 = fa_light_texel(param_33);\n            if (_1157.z > 0.5)\n            {\n                int param_34 = _773 + 2;\n                int param_35 = _773 + 4;\n                int param_36 = _773 + 5;\n                vec2 param_37 = _1157.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_777 && _1009)\n            {\n                int param_42 = _773 + 6;\n                vec4 _1204 = fa_light_texel(param_42);\n                int param_43 = _773 + 7;\n                vec4 _1209 = fa_light_texel(param_43);\n                bool _1212 = _1204.z > 0.5;\n                bool _1219;\n                if (!_1212)\n                {\n                    _1219 = _1209.z > 0.5;\n                }\n                else\n                {\n                    _1219 = _1212;\n                }\n                if (_1219)\n                {\n                    int param_44 = _773 + 2;\n                    vec4 _1226 = fa_light_texel(param_44);\n                    vec3 _1230 = normalize(_1226.xyz);\n                    int param_45 = _773 + 4;\n                    vec4 _1235 = fa_light_texel(param_45);\n                    int param_46 = _773 + 5;\n                    vec4 _1240 = fa_light_texel(param_46);\n                    if (_1212)\n                    {\n                        vec3 _1248 = -to_light;\n                        float _1255 = _1226.w;\n                        float _1271 = 0.5 / max(dot(_1248, _1230) * (sqrt(max(1.0 - (_1255 * _1255), 0.0)) / max(_1255, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1204.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1248, _1235.xyz) * _1271), 0.5 - (dot(_1248, _1240.xyz) * _1271));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1209.z > 0.5)\n                    {\n                        vec2 param_49 = _1209.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1230;\n                        vec3 param_52 = _1235.xyz;\n                        vec3 param_53 = _1240.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5062 = _786.xyz * atten;\n    if (_777)\n    {\n        _5062 *= fa_light_tint;\n    }\n    int _1339;\n    if (_803)\n    {\n        _1339 = 0;\n    }\n    else\n    {\n        _1339 = ((_789 > 1.5) && (_789 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5062, atten, 1.0, dist, _1339);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2076;\n    if (i == 0)\n    {\n        _2076 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2092;\n        if (i == 1)\n        {\n            _2092 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2100;\n            if (i == 2)\n            {\n                _2100 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2100 = fa_shadows[24].w;\n            }\n            _2092 = _2100;\n        }\n        _2076 = _2092;\n    }\n    return _2076;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2133 = fa_shadow_depth(param, param_1);\n    float _2137;\n    if (conv.x < 0.5)\n    {\n        _2137 = _2133;\n    }\n    else\n    {\n        _2137 = (conv.y * conv.z) / (conv.z - (_2133 * (conv.z - conv.y)));\n    }\n    return _2137;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2064 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2064), sin(_2064)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2183 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2192;\n        if (k < 0.0)\n        {\n            _2192 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2192 = k;\n        }\n        float _2212 = clamp((_2192 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2183;\n            vec2 _2231 = fa_shadow_vogel(param_3, param_4, param_5) * _2212;\n            vec2 param_6 = uv + (_2231 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2243 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2243 < (zr - (length(_2231) * plane)))\n            {\n                sum += _2243;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2269 = sum / cnt;\n        float _2279;\n        if (k < 0.0)\n        {\n            _2279 = (-k) / max(_2269, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2279 = k;\n        }\n        radius = clamp(((max(zr - _2269, 0.0) * unit) * _2279) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2301 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2301; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2301;\n        float param_11 = _2183;\n        vec2 _2320 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2320 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2320) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2301);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2362 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2367 = clamp(dot(n, l), 0.0, 1.0);\n    float _2373 = sqrt(1.0 - (_2367 * _2367));\n    float _2380 = min(_2373 / max(_2367, 0.20000000298023223876953125), 4.0);\n    float _2385;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2385 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2385 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2410 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2385 * _2373)), 1.0);\n    float _2417 = _2410.x;\n    bool _2420 = _2417 < fa_shadows[ci * 1 + 16].x;\n    bool _2429;\n    if (!_2420)\n    {\n        _2429 = _2417 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2429 = _2420;\n    }\n    bool _2438;\n    if (!_2429)\n    {\n        _2438 = _2410.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2438 = _2429;\n    }\n    bool _2447;\n    if (!_2438)\n    {\n        _2447 = _2410.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2447 = _2438;\n    }\n    bool _2454;\n    if (!_2447)\n    {\n        _2454 = _2410.z > 1.0;\n    }\n    else\n    {\n        _2454 = _2447;\n    }\n    if (_2454)\n    {\n        return -1.0;\n    }\n    float _2462;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2462 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2462 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2410.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2410.z - ((_2462 * (1.0 + (0.5 * _2380))) / _2362);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2362;\n    float param_5 = _2362 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2380, 3.0)) * 0.5) / _2362;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2840 = int(fa_shadows[25].x + 0.5);\n    if (_2840 < 1)\n    {\n        return 1.0;\n    }\n    float _2855 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2840 - 1;\n    if (_2855 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2867 = _2840 > 1;\n    bool _2874;\n    if (_2867)\n    {\n        _2874 = _2855 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2874 = _2867;\n    }\n    if (_2874)\n    {\n        ci = 1;\n    }\n    bool _2878 = _2840 > 2;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2855 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 2;\n    }\n    bool _2889 = _2840 > 3;\n    bool _2896;\n    if (_2889)\n    {\n        _2896 = _2855 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2840)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2922 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2922;\n        if (_2922 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2947;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2947 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2947 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2966 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2947, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2977 = clamp((_2855 - (fa_shadow_split_at(param_7) - _2966)) / _2966, 0.0, 1.0);\n        if (_2977 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2840)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2998 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2998;\n                if (_2998 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2977);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2520 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2527;\n    if (!_2520)\n    {\n        _2527 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2527 = _2520;\n    }\n    if (_2527)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2540 = fa_light_texel(param);\n    float _2541 = _2540.x;\n    if (_2541 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2550 = int(_2541 + 0.5);\n    int param_1 = _2550;\n    vec4 _2554 = fa_light_texel(param_1);\n    int param_2 = _2550 + 1;\n    vec4 _2559 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2562 = _2554.y;\n    if (_2562 > 0.0)\n    {\n        float _2579 = 1.0 - smoothstep(0.75 * _2562, _2562, length(world - fa_shadows[27].xyz));\n        fade = _2579;\n        if (_2579 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2554.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2603 = (_2550 + 2) + (face * 6);\n    int param_4 = _2603;\n    int param_5 = _2603 + 1;\n    int param_6 = _2603 + 3;\n    vec4 _2617 = fa_light_texel(param_6);\n    int param_7 = _2603 + 4;\n    vec4 _2622 = fa_light_texel(param_7);\n    int param_8 = _2603 + 5;\n    vec4 _2627 = fa_light_texel(param_8);\n    float _2639 = _2627.x * max(dot(_2617, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2644 = clamp(dot(n, l), 0.0, 1.0);\n    float _2667 = clamp(dot(n, _2617.xyz), -1.0, 1.0);\n    float _2686 = min(sqrt(1.0 - (_2667 * _2667)) / max(abs(dot(n, world - lpos)) / max(dot(_2617, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2689 = _2559.y;\n    float _2691;\n    if (_2689 > 0.0)\n    {\n        _2691 = _2689;\n    }\n    else\n    {\n        _2691 = 1.5 * _2639;\n    }\n    vec4 _2711 = vec4(world + (n * (_2691 * sqrt(1.0 - (_2644 * _2644)))), 1.0);\n    float _2715 = dot(_2617, _2711);\n    float _2718 = _2627.y;\n    if (_2715 < _2718)\n    {\n        return 1.0;\n    }\n    vec2 _2733 = vec2(dot(fa_light_texel(param_4), _2711), dot(fa_light_texel(param_5), _2711)) / vec2(_2715);\n    float _2735 = _2733.x;\n    bool _2738 = _2735 < _2622.x;\n    bool _2747;\n    if (!_2738)\n    {\n        _2747 = _2735 > _2622.z;\n    }\n    else\n    {\n        _2747 = _2738;\n    }\n    bool _2756;\n    if (!_2747)\n    {\n        _2756 = _2733.y < _2622.y;\n    }\n    else\n    {\n        _2756 = _2747;\n    }\n    bool _2765;\n    if (!_2756)\n    {\n        _2765 = _2733.y > _2622.w;\n    }\n    else\n    {\n        _2765 = _2756;\n    }\n    if (_2765)\n    {\n        return 1.0;\n    }\n    float _2771 = _2559.x;\n    float _2773;\n    if (_2771 > 0.0)\n    {\n        _2773 = _2771;\n    }\n    else\n    {\n        _2773 = 1.5 * _2639;\n    }\n    vec2 param_9 = _2733;\n    vec4 param_10 = _2622;\n    float param_11 = _2715 - (_2773 * (1.0 + (0.5 * _2686)));\n    float param_12 = _2639;\n    float param_13 = 1.0;\n    float param_14 = _2627.z * 0.25;\n    float param_15 = (_2639 * min(_2686, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2718, _2627.z);\n    int param_17 = int(_2554.z + 0.5);\n    float param_18 = _2554.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4073 = fa_lm.z > 0.5;\n    bool _4079;\n    if (_4073)\n    {\n        int param = li;\n        _4079 = fa_light_baked(param);\n    }\n    else\n    {\n        _4079 = _4073;\n    }\n    if (_4079)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4103 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5195 = _4103.color;\n    float _5197 = _4103.shadow;\n    if ((_4103.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4103.direction;\n        float _4117 = fa_shadow_factor(param_5, param_6);\n        _5197 = _4117;\n        _5195 *= _4117;\n    }\n    else\n    {\n        bool _4128 = _4103.type != 0;\n        bool _4134;\n        if (_4128)\n        {\n            _4134 = _4103.attenuation > 0.0;\n        }\n        else\n        {\n            _4134 = _4128;\n        }\n        if (_4134)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4103.direction;\n            float _4153 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5197 = _4153;\n            _5195 *= _4153;\n        }\n    }\n    return LightSample(_4103.direction, _5195, _4103.attenuation, _5197, _4103._distance, _4103.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3022 = int(fa_shadows[25].x + 0.5);\n    float _3032 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3037 = _3022 > 0;\n    bool _3046;\n    if (_3037)\n    {\n        int param = _3022 - 1;\n        _3046 = _3032 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3046 = _3037;\n    }\n    if (_3046)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3052 = _3022 > 1;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3032 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3065 = _3022 > 2;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3032 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3078 = _3022 > 3;\n        bool _3085;\n        if (_3078)\n        {\n            _3085 = _3032 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3085 = _3078;\n        }\n        if (_3085)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4904 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4904 = -_4904;\n    }\n    vec3 _4539 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing);\n    Surface _4547 = fa_standard_surface(param_1);\n    vec3 _4943 = _4547.albedo;\n    float _4944 = _4547.alpha;\n    vec3 _4945 = _4547.normal;\n    float _4946 = _4547.metallic;\n    float _4947 = _4547.roughness;\n    float _4948 = _4547.occlusion;\n    vec3 _4949 = _4547.emission;\n    float _4950 = _4547.clearcoat;\n    float _4951 = _4547.clearcoat_roughness;\n    vec3 _4952 = _4547.sheen_color;\n    float _4953 = _4547.sheen_roughness;\n    float _4954 = _4547.anisotropy;\n    float _4955 = _4547.anisotropy_rotation;\n    float _4956 = _4547.specular;\n    float _4957 = _4547.ior;\n    vec3 _4958 = _4547.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing);\n    Surface param_3 = _4547;\n    surface(param_2, param_3);\n    _4943 = param_3.albedo;\n    _4944 = param_3.alpha;\n    _4945 = param_3.normal;\n    _4946 = param_3.metallic;\n    _4947 = param_3.roughness;\n    _4948 = param_3.occlusion;\n    _4949 = param_3.emission;\n    _4950 = param_3.clearcoat;\n    _4951 = param_3.clearcoat_roughness;\n    _4952 = param_3.sheen_color;\n    _4953 = param_3.sheen_roughness;\n    _4954 = param_3.anisotropy;\n    _4955 = param_3.anisotropy_rotation;\n    _4956 = param_3.specular;\n    _4957 = param_3.ior;\n    _4958 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4904;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4943 = param_6;\n    _4945 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4943;\n    }\n    else\n    {\n        vec3 _4585 = _4945;\n        vec3 _4586 = normalize(_4585);\n        _4945 = _4586;\n        vec3 param_8 = _4586;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing);\n        Surface param_10 = Surface(_4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4605 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4605; ln++)\n        {\n            int param_12 = ln;\n            int _4618 = fa_cl_light(param_12);\n            bool _4621 = fa_lm.z > 0.5;\n            bool _4627;\n            if (_4621)\n            {\n                int param_13 = _4618;\n                _4627 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4627 = _4621;\n            }\n            if (_4627)\n            {\n                continue;\n            }\n            int param_14 = _4618;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _4904;\n            LightSample _4639 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing);\n            Surface param_18 = Surface(_4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958);\n            LightSample param_19 = _4639;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _4654 = result;\n    vec3 _4655 = _4654 + _4949;\n    result = _4655;\n    vec3 param_20 = _4655;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4664 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4671;\n    if (!_4664)\n    {\n        _4671 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4671 = _4664;\n    }\n    if (_4671)\n    {\n        vec3 _4680 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4686 = dot(_4680, fa_mesh_fs_params[9].xyz);\n        bool _4690 = fa_mesh_fs_params[9].w > 0.5;\n        float _4691;\n        if (_4690)\n        {\n            _4691 = _4686;\n        }\n        else\n        {\n            _4691 = length(_4680);\n        }\n        float _4703 = _4691 - fa_mesh_fs_params[8].x;\n        if (_4703 > 0.0)\n        {\n            float _4712 = fa_mesh_fs_params[7].w * _4703;\n            float tau = _4712 * _4712;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4728;\n                if (_4690)\n                {\n                    _4728 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4686);\n                }\n                else\n                {\n                    _4728 = fa_mesh_fs_params[0].y;\n                }\n                float _4749 = mix(_4728, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4691, 0.0, 1.0));\n                float _4753 = fa_world_pos.y - _4749;\n                float _4758 = _4749 - fa_mesh_fs_params[8].z;\n                float _4763 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4766 = _4758 <= 0.0;\n                bool _4767 = !_4766;\n                bool _4773;\n                if (_4767)\n                {\n                    _4773 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4773 = _4766;\n                }\n                float _4774;\n                if (_4773)\n                {\n                    _4774 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4774 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4758, 80.0));\n                }\n                bool _4801;\n                if (_4767)\n                {\n                    _4801 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4801 = _4766;\n                }\n                float _4802;\n                if (_4801)\n                {\n                    _4802 = fa_mesh_fs_params[8].y * _4758;\n                }\n                else\n                {\n                    _4802 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4758, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4827 = _4763 <= 0.0;\n                bool _4834;\n                if (!_4827)\n                {\n                    _4834 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4834 = _4827;\n                }\n                float _4835;\n                if (_4834)\n                {\n                    _4835 = fa_mesh_fs_params[8].y * _4763;\n                }\n                else\n                {\n                    _4835 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4763, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4862;\n                if (abs(_4753) < 0.001000000047497451305389404296875)\n                {\n                    _4862 = _4774;\n                }\n                else\n                {\n                    _4862 = (_4835 - _4802) / _4753;\n                }\n                tau += (_4703 * max(_4862, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4944);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_429",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
            "inst_name": "_2086",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3516[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1357 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1372;\n    if (!_1364)\n    {\n        _1372 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1372 = _1364;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    bool _1386;\n    if (!_1379)\n    {\n        _1386 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1386 = _1379;\n    }\n    if (_1386)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1396 = vec4(world_pos, 1.0);\n    float _1402 = dot(fa_mesh_fs_params[16], _1396);\n    if (!(_1402 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1424 = vec2(dot(fa_mesh_fs_params[14], _1396), dot(fa_mesh_fs_params[15], _1396)) / vec2(_1402);\n    int _1428 = int(fa_mesh_fs_params[18].x);\n    int _1432 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1432) + clamp(int(floor(((_1424.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1432 - 1)) * _1428)) + clamp(int(floor(((_1424.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1428 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1508 = fa_cluster_texel(param);\n    return ivec2(int(_1508.x), int(_1508.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4046 = fa_cluster_lookup(param);\n    fa_cl_slot = _4046.x;\n    fa_cl_local = _4046.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4209 = fa_linear_to_srgb(param);\n        c = _4209;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4217 = fa_srgb_to_linear(param_1);\n            c = _4217;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _312;\n    if (i.front_facing)\n    {\n        _312 = i.world_normal;\n    }\n    else\n    {\n        _312 = -i.world_normal;\n    }\n    vec3 _336 = normalize(i.world_tangent.xyz - (_312 * dot(_312, i.world_tangent.xyz)));\n    vec3 _363 = normalize(((_336 * m.x) + ((cross(_312, _336) * i.world_tangent.w) * m.y)) + (_312 * m.z));\n    vec3 _366;\n    if (i.front_facing)\n    {\n        _366 = _363;\n    }\n    else\n    {\n        _366 = -_363;\n    }\n    return _366;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4248 = fa_tex_fix(param_2, param_3);\n    vec4 _5363 = base_t;\n    _5363.x = _4248.x;\n    _5363.y = _4248.y;\n    _5363.z = _4248.z;\n    base_t = _5363;\n    vec4 _4262 = (_5363 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5215 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4294 = fa_tex_fix(param_6, param_7);\n        vec3 _4297 = (_4294 * 2.0) - vec3(1.0);\n        vec2 _4302 = _4297.xy * fa_mesh_fs_params[6].x;\n        vec3 _5371 = _4297;\n        _5371.x = _4302.x;\n        _5371.y = _4302.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5371;\n        _5215 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4330 = fa_tex_fix(param_12, param_13);\n    vec4 _5374 = mrt;\n    _5374.x = _4330.x;\n    _5374.y = _4330.y;\n    _5374.z = _4330.z;\n    mrt = _5374;\n    vec4 _4358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4369 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4399 = fa_tex_fix(param_20, param_21);\n    float _5220 = fa_mesh_fs_params[20].x;\n    float _5221 = fa_mesh_fs_params[20].y;\n    float _5224 = fa_mesh_fs_params[20].z;\n    float _5223 = fa_mesh_fs_params[21].w;\n    float _5226 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5220 *= _4369.y;\n            _5221 *= _4369.z;\n            _5223 *= _4358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5224 *= mrt.x;\n            _5226 *= mrt.w;\n        }\n    }\n    return Surface(_4262.xyz, _4262.w, _5215, clamp(fa_mesh_fs_params[5].x * _4330.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4330.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4369.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4399), _5220, _5221, fa_mesh_fs_params[21].xyz, _5223, _5224, fa_mesh_fs_params[20].w, _5226, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1588 = rect.zw - rect.xy;\n    vec2 _1592 = _1588 * atlas;\n    vec2 _1596 = ddx * _1592;\n    vec2 _1600 = ddy * _1592;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1588), clamp(0.5 * log2(max(max(dot(_1596, _1596), dot(_1600, _1600)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1633 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return;\n    }\n    vec3 _1646 = dFdx(world_pos);\n    vec3 _1649 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1653 = fa_cluster_texel(param);\n    int _1657 = int(_1653.w);\n    if (_1657 < 1)\n    {\n        return;\n    }\n    int _1667 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1667;\n    vec4 _1671 = fa_light_texel(param_1);\n    vec2 _1674 = _1671.yz;\n    int _1678 = int(_1671.w);\n    int param_2 = _1667 + 1;\n    vec4 _1683 = fa_light_texel(param_2);\n    float _1684 = _1683.x;\n    int _1690 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1694 = int(_1653.z);\n    vec3 _1959;\n    for (int k = 0; k < _1657; k++)\n    {\n        int _1707 = _1694 + k;\n        int param_3 = _1678 + (_1707 >> 2);\n        int _1724 = (_1667 + 2) + (int(fa_light_texel(param_3)[_1707 & 3]) * 7);\n        int param_4 = _1724 + 6;\n        vec4 _1729 = fa_light_texel(param_4);\n        if (((int(_1729.w + 0.5) >> _1690) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1724;\n        vec4 _1744 = fa_light_texel(param_5);\n        int param_6 = _1724 + 1;\n        vec4 _1749 = fa_light_texel(param_6);\n        int param_7 = _1724 + 2;\n        vec4 _1754 = fa_light_texel(param_7);\n        vec3 _1757 = _1744.xyz;\n        float _1762 = dot(_1757, world_pos) + _1744.w;\n        vec3 _1764 = _1749.xyz;\n        float _1769 = dot(_1764, world_pos) + _1749.w;\n        vec3 _1771 = _1754.xyz;\n        float _1776 = dot(_1771, world_pos) + _1754.w;\n        bool _1781 = abs(_1762) > 0.5;\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1769) > 0.5;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1776) > 0.5;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        if (_1797)\n        {\n            continue;\n        }\n        float _1812 = clamp(dot(geo_normal, normalize(_1771)) * _1729.z, 0.0, 1.0);\n        if (_1812 <= 0.0)\n        {\n            continue;\n        }\n        float _1832 = (clamp((0.5 - abs(_1776)) * 10.0, 0.0, 1.0) * _1812) * _1729.x;\n        vec2 _1840 = vec2(_1762 + 0.5, 0.5 - _1769);\n        vec2 _1850 = vec2(dot(_1757, _1646), dot(_1764, _1646));\n        vec2 _1860 = vec2(dot(_1757, _1649), dot(_1764, _1649));\n        int param_8 = _1724 + 5;\n        vec4 _1865 = fa_light_texel(param_8);\n        int param_9 = _1724 + 3;\n        vec4 _1870 = fa_light_texel(param_9);\n        int param_10 = _1724 + 4;\n        vec4 _1875 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1865.xyz;\n        bool _1885 = _1870.z > _1870.x;\n        if (_1885)\n        {\n            vec4 param_11 = _1870;\n            vec2 param_12 = _1840;\n            vec2 param_13 = _1674;\n            vec2 param_14 = _1850;\n            vec2 param_15 = _1860;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1684 > 0.5) && (_1684 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1911 = fa_dc_to_linear(param_16);\n                vec4 _5295 = tx;\n                _5295.x = _1911.x;\n                _5295.y = _1911.y;\n                _5295.z = _1911.z;\n                tx = _5295;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1832 * tex_a) * _1865.w, 0.0, 1.0)));\n        if (_1875.z > _1875.x)\n        {\n            vec4 param_17 = _1875;\n            vec2 param_18 = _1840;\n            vec2 param_19 = _1674;\n            vec2 param_20 = _1850;\n            vec2 param_21 = _1860;\n            vec4 _1955 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1684 > 1.5)\n            {\n                vec3 param_22 = _1955.xyz;\n                vec3 _1965 = fa_dc_to_srgb(param_22);\n                _1959 = _1965;\n            }\n            else\n            {\n                _1959 = _1955.xyz;\n            }\n            vec3 _1974 = (_1959 * 2.0) - vec3(1.0);\n            vec2 _1979 = _1974.xy * _1729.y;\n            vec3 _2001 = (normalize(_1757) * _1979.x) + (normalize(_1764) * _1979.y);\n            vec3 _2004 = normalize(normal);\n            normal = normalize(mix(_2004, normalize((_2004 * max(_1974.z, 0.0500000007450580596923828125)) + (_2001 - (_2004 * dot(_2004, _2001)))), vec3(clamp(_1832 * (_1885 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3199 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3199;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3442 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3449 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3452 = int(_3442);\n    int _3455 = int(_3449);\n    float _3465 = _3449 - float(_3455);\n    int _3520 = (_3452 * 9) + _3455;\n    int _3540 = ((_3452 + 1) * 9) + _3455;\n    return mix(mix(_3516[_3520], _3516[_3520 + 1], _3465), mix(_3516[_3540], _3516[_3540 + 1], _3465), _3442 - float(_3452));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5074 = false;\n    float _5075 = 1.0;\n    float _5076 = 1.0;\n    float _5077 = 1.0;\n    float _5078 = 0.0;\n    float _5079 = 0.0;\n    float _5080 = 0.0;\n    float _5081 = 0.0;\n    float _5083 = 1.0;\n    bool _5084 = false;\n    vec3 _5085 = vec3(0.0);\n    float _5086 = 1.0;\n    float _5087 = 1.0;\n    float _5088 = 1.0;\n    float _5089 = 0.0;\n    float _5090 = 0.0;\n    vec3 _5091 = vec3(1.0, 0.0, 0.0);\n    vec3 _5092 = vec3(0.0, 0.0, 1.0);\n    float _5093 = 1.0;\n    float _5094 = 1.0;\n    float _3591 = clamp(s.specular, 0.0, 1.0);\n    float _3595 = clamp(s.ior, 1.0, 3.0);\n    bool _3600 = (_3591 != 1.0) || (_3595 != 1.5);\n    bool _3609;\n    if (!_3600)\n    {\n        _3609 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3609 = _3600;\n    }\n    if (_3609)\n    {\n        float _3617 = (_3595 - 1.0) / (_3595 + 1.0);\n        f0 = mix(min(vec3(_3617 * _3617) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3591, s.albedo, vec3(metallic));\n        _5075 = mix(_3591, 1.0, metallic);\n        _5074 = true;\n    }\n    float _3644 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3644 > 0.0)\n    {\n        float _3652 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5078 = _3644;\n        _5079 = _3652;\n        float _3659 = _3652 * _3652;\n        _5080 = _3659;\n        _5081 = _3659 * _3659;\n        float _3671 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5083 = _3671;\n        _5076 = 1.0 - (_3644 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3671, 0.0, 1.0), 5.0))));\n        _5074 = true;\n    }\n    vec3 _3690 = max(s.sheen_color, vec3(0.0));\n    float _3699 = max(_3690.x, max(_3690.y, _3690.z));\n    if (_3699 > 0.0)\n    {\n        float _3707 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5084 = true;\n        _5085 = _3690;\n        _5086 = _3707;\n        _5087 = _3707 * _3707;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3707;\n        float _3724 = fa_sheen_albedo(param, param_1);\n        _5089 = _3724;\n        _5088 = 1.0 - min(_3699 * _3724, 1.0);\n        _5074 = true;\n    }\n    _5077 = _5076 * _5088;\n    float _3743 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3743 != 0.0)\n    {\n        vec3 _3758 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3758;\n        if (dot(_3758, _3758) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3770 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3770.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3770.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3770.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3774 = t;\n        vec3 _3775 = normalize(_3774);\n        t = _3775;\n        vec3 _3800 = normalize((_3775 * cos(s.anisotropy_rotation)) + ((cross(n, _3775) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5091 = _3800;\n        _5092 = cross(n, _3800);\n        float _3810 = roughness * roughness;\n        float _3816 = mix(_3810, 1.0, _3743 * _3743);\n        bool _3818 = _3743 > 0.0;\n        _5093 = _3818 ? _3816 : _3810;\n        _5094 = _3818 ? _3810 : _3816;\n        _5090 = _3743;\n        _5074 = true;\n    }\n    return FaLayers(_5074, _5075, _5076, _5077, _5078, _5079, _5080, _5081, i.world_normal, _5083, _5084, _5085, _5086, _5087, _5088, _5089, _5090, _5091, _5092, _5093, _5094);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3374 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3377 = _3374.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3377 * _3377, exp2((-9.27999973297119140625) * ndv)) * _3377) + _3374.y)) + _3374.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3228 = rough * rough;\n    float _3258 = 0.60000002384185791015625 * _3228;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3228)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3258, 0.0500000007450580596923828125 + _3258, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3228 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3851;\n        if (L.aniso >= 0.0)\n        {\n            _3851 = L.b;\n        }\n        else\n        {\n            _3851 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3851, v), _3851), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3884 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3884.x) + (vec3(L.f90) * _3884.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3939 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3939.x) + _3939.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3416 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3416.x) + vec3(_3416.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3968 = clamp(s.metallic, 0.0, 1.0);\n    float _3972 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3979 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3968));\n    vec3 f0 = _3979;\n    vec3 _3983 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3983;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3968;\n    float param_5 = _3972;\n    vec3 param_6 = _3979;\n    FaLayers _4000 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4000.on)\n    {\n        FaLayers param_7 = _4000;\n        vec3 param_8 = _3983;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3972;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3983;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3972;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _607 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _620 = (c - (ru * hx)) - p;\n        vec3 _626 = ru * (2.0 * hx);\n        float _632 = max(dot(_626, _626), 9.9999999392252902907785028219223e-09);\n        float _636 = dot(_620, _626);\n        float t = clamp((-_636) / _632, 0.0, 1.0);\n        if (_607)\n        {\n            float _651 = dot(r, _626);\n            float _657 = _632 - (_651 * _651);\n            if (abs(_657) > (9.9999997473787516355514526367188e-06 * _632))\n            {\n                t = clamp(((dot(r, _620) * _651) - _636) / _657, 0.0, 1.0);\n            }\n        }\n        return (p + _620) + (_626 * t);\n    }\n    vec3 q = p;\n    float _689 = dot(r, axis);\n    bool _697;\n    if (_607)\n    {\n        _697 = abs(_689) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _697 = _607;\n    }\n    if (_697)\n    {\n        float _707 = dot(c - p, axis) / _689;\n        if (_707 > 0.0)\n        {\n            q = p + (r * _707);\n        }\n    }\n    vec3 _720 = q - c;\n    vec2 xy = vec2(dot(_720, ru), dot(_720, uu));\n    if (shape > 0.5)\n    {\n        float _735 = length(xy);\n        if (_735 > hx)\n        {\n            xy *= (hx / _735);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _378 = abs(d);\n    float _380 = _378.x;\n    float _382 = _378.y;\n    bool _383 = _380 >= _382;\n    bool _391;\n    if (_383)\n    {\n        _391 = _380 >= _378.z;\n    }\n    else\n    {\n        _391 = _383;\n    }\n    int _392;\n    if (_391)\n    {\n        _392 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _407;\n        if (_382 >= _378.z)\n        {\n            _407 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _407 = (d.z > 0.0) ? 4 : 5;\n        }\n        _392 = _407;\n    }\n    return _392;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _527 = dot(d, right);\n    float _531 = dot(d, up);\n    float _542;\n    if (((_527 * _527) + (_531 * _531)) > 1.0000000133514319600180897396058e-10)\n    {\n        _542 = atan(_531, _527) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _542 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_542 - floor(_542)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _773 = fa_light_base(param);\n    bool _777 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _773;\n    vec4 _781 = fa_light_texel(param_1);\n    int param_2 = _773 + 1;\n    vec4 _786 = fa_light_texel(param_2);\n    float _789 = _786.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _801 = _777 && (_789 > 2.5);\n    fa_light_is_area = _801;\n    bool _803 = _789 < 0.5;\n    vec3 l;\n    if (_803)\n    {\n        l = normalize(_781.xyz);\n        if (_777)\n        {\n            int param_3 = _773 + 6;\n            vec4 _817 = fa_light_texel(param_3);\n            if (_817.z > 0.5)\n            {\n                int param_4 = _773 + 4;\n                vec4 _827 = fa_light_texel(param_4);\n                int param_5 = _773 + 5;\n                vec4 _832 = fa_light_texel(param_5);\n                vec2 param_6 = _817.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _827.xyz) * _827.w, (-dot(world_pos, _832.xyz)) * _832.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _862 = _781.xyz;\n        vec3 _864 = _862 - world_pos;\n        vec3 to_light = _864;\n        float _867 = length(_864);\n        float reach = _867;\n        bool front = true;\n        if (_801)\n        {\n            int param_8 = _773 + 7;\n            reach = max(_867 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _773 + 4;\n            vec4 _891 = fa_light_texel(param_9);\n            int param_10 = _773 + 5;\n            vec4 _896 = fa_light_texel(param_10);\n            int param_11 = _773 + 6;\n            vec4 _901 = fa_light_texel(param_11);\n            float _902 = _901.w;\n            int param_12 = _773 + 2;\n            vec3 _909 = normalize(fa_light_texel(param_12).xyz);\n            bool _911 = _902 > 1.5;\n            bool _919;\n            if (!_911)\n            {\n                _919 = dot(_909, to_light) < 0.0;\n            }\n            else\n            {\n                _919 = _911;\n            }\n            front = _919;\n            vec3 r = vec3(0.0);\n            vec3 _928 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _932 = dot(n, n) > 0.5;\n            bool _940;\n            if (_932)\n            {\n                _940 = dot(_928, _928) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _940 = _932;\n            }\n            if (_940)\n            {\n                r = reflect(-normalize(_928), normalize(n));\n            }\n            vec3 param_13 = _862;\n            vec3 param_14 = _909;\n            vec3 param_15 = _891.xyz;\n            vec3 param_16 = _896.xyz;\n            float param_17 = _891.w;\n            float param_18 = _896.w;\n            float param_19 = _902;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _976 = length(to_light);\n        dist = _976;\n        l = to_light / vec3(max(_976, 9.9999997473787516355514526367188e-05));\n        float _990 = reach / max(_781.w, 0.001000000047497451305389404296875);\n        float _996 = clamp(1.0 - (_990 * _990), 0.0, 1.0);\n        float _998;\n        if (front)\n        {\n            _998 = _996 * _996;\n        }\n        else\n        {\n            _998 = 0.0;\n        }\n        atten = _998;\n        bool _1009 = _789 < 2.5;\n        if ((_789 > 1.5) && _1009)\n        {\n            int param_22 = _773 + 2;\n            vec4 _1017 = fa_light_texel(param_22);\n            float _1027 = _1017.w;\n            int param_23 = _773 + 3;\n            vec4 _1032 = fa_light_texel(param_23);\n            float _1033 = _1032.x;\n            float cos_inner = _1033;\n            if (_1033 > 1.5)\n            {\n                cos_inner = mix(_1027, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1027, cos_inner, dot(-l, normalize(_1017.xyz)));\n        }\n        if (_777 && (_789 < 1.5))\n        {\n            int param_24 = _773 + 6;\n            vec4 _1057 = fa_light_texel(param_24);\n            if (_1057.z > 0.5)\n            {\n                vec3 _1065 = -to_light;\n                int param_25 = _773 + 4;\n                int param_26 = _773 + 5;\n                vec3 _1079 = fa_light_texel(param_25).xyz;\n                vec3 _1083 = fa_light_texel(param_26).xyz;\n                vec3 _1092 = vec3(dot(_1065, _1079), dot(_1065, _1083), dot(_1065, cross(_1079, _1083)));\n                vec3 param_27 = _1092;\n                int _1096 = fa_cube_face(param_27);\n                int param_28 = _1096;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1123 = vec2(dot(_1092, cross(param_29, param_30)), dot(_1092, param_30)) / vec2(max(dot(_1092, param_29), 9.9999997473787516355514526367188e-05));\n                int _1127 = _1096 / 3;\n                vec2 param_31 = _1057.xy + (vec2(float(_1096 - (_1127 * 3)), float(_1127)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1123.x), 0.5 - (0.5 * _1123.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _773 + 7;\n            vec4 _1157 = fa_light_texel(param_33);\n            if (_1157.z > 0.5)\n            {\n                int param_34 = _773 + 2;\n                int param_35 = _773 + 4;\n                int param_36 = _773 + 5;\n                vec2 param_37 = _1157.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_777 && _1009)\n            {\n                int param_42 = _773 + 6;\n                vec4 _1204 = fa_light_texel(param_42);\n                int param_43 = _773 + 7;\n                vec4 _1209 = fa_light_texel(param_43);\n                bool _1212 = _1204.z > 0.5;\n                bool _1219;\n                if (!_1212)\n                {\n                    _1219 = _1209.z > 0.5;\n                }\n                else\n                {\n                    _1219 = _1212;\n                }\n                if (_1219)\n                {\n                    int param_44 = _773 + 2;\n                    vec4 _1226 = fa_light_texel(param_44);\n                    vec3 _1230 = normalize(_1226.xyz);\n                    int param_45 = _773 + 4;\n                    vec4 _1235 = fa_light_texel(param_45);\n                    int param_46 = _773 + 5;\n                    vec4 _1240 = fa_light_texel(param_46);\n                    if (_1212)\n                    {\n                        vec3 _1248 = -to_light;\n                        float _1255 = _1226.w;\n                        float _1271 = 0.5 / max(dot(_1248, _1230) * (sqrt(max(1.0 - (_1255 * _1255), 0.0)) / max(_1255, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1204.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1248, _1235.xyz) * _1271), 0.5 - (dot(_1248, _1240.xyz) * _1271));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1209.z > 0.5)\n                    {\n                        vec2 param_49 = _1209.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1230;\n                        vec3 param_52 = _1235.xyz;\n                        vec3 param_53 = _1240.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5062 = _786.xyz * atten;\n    if (_777)\n    {\n        _5062 *= fa_light_tint;\n    }\n    int _1339;\n    if (_803)\n    {\n        _1339 = 0;\n    }\n    else\n    {\n        _1339 = ((_789 > 1.5) && (_789 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5062, atten, 1.0, dist, _1339);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2076;\n    if (i == 0)\n    {\n        _2076 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2092;\n        if (i == 1)\n        {\n            _2092 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2100;\n            if (i == 2)\n            {\n                _2100 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2100 = fa_shadows[24].w;\n            }\n            _2092 = _2100;\n        }\n        _2076 = _2092;\n    }\n    return _2076;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2133 = fa_shadow_depth(param, param_1);\n    float _2137;\n    if (conv.x < 0.5)\n    {\n        _2137 = _2133;\n    }\n    else\n    {\n        _2137 = (conv.y * conv.z) / (conv.z - (_2133 * (conv.z - conv.y)));\n    }\n    return _2137;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2064 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2064), sin(_2064)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2183 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2192;\n        if (k < 0.0)\n        {\n            _2192 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2192 = k;\n        }\n        float _2212 = clamp((_2192 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2183;\n            vec2 _2231 = fa_shadow_vogel(param_3, param_4, param_5) * _2212;\n            vec2 param_6 = uv + (_2231 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2243 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2243 < (zr - (length(_2231) * plane)))\n            {\n                sum += _2243;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2269 = sum / cnt;\n        float _2279;\n        if (k < 0.0)\n        {\n            _2279 = (-k) / max(_2269, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2279 = k;\n        }\n        radius = clamp(((max(zr - _2269, 0.0) * unit) * _2279) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2301 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2301; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2301;\n        float param_11 = _2183;\n        vec2 _2320 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2320 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2320) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2301);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2362 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2367 = clamp(dot(n, l), 0.0, 1.0);\n    float _2373 = sqrt(1.0 - (_2367 * _2367));\n    float _2380 = min(_2373 / max(_2367, 0.20000000298023223876953125), 4.0);\n    float _2385;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2385 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2385 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2410 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2385 * _2373)), 1.0);\n    float _2417 = _2410.x;\n    bool _2420 = _2417 < fa_shadows[ci * 1 + 16].x;\n    bool _2429;\n    if (!_2420)\n    {\n        _2429 = _2417 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2429 = _2420;\n    }\n    bool _2438;\n    if (!_2429)\n    {\n        _2438 = _2410.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2438 = _2429;\n    }\n    bool _2447;\n    if (!_2438)\n    {\n        _2447 = _2410.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2447 = _2438;\n    }\n    bool _2454;\n    if (!_2447)\n    {\n        _2454 = _2410.z > 1.0;\n    }\n    else\n    {\n        _2454 = _2447;\n    }\n    if (_2454)\n    {\n        return -1.0;\n    }\n    float _2462;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2462 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2462 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2410.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2410.z - ((_2462 * (1.0 + (0.5 * _2380))) / _2362);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2362;\n    float param_5 = _2362 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2380, 3.0)) * 0.5) / _2362;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2840 = int(fa_shadows[25].x + 0.5);\n    if (_2840 < 1)\n    {\n        return 1.0;\n    }\n    float _2855 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2840 - 1;\n    if (_2855 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2867 = _2840 > 1;\n    bool _2874;\n    if (_2867)\n    {\n        _2874 = _2855 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2874 = _2867;\n    }\n    if (_2874)\n    {\n        ci = 1;\n    }\n    bool _2878 = _2840 > 2;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2855 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 2;\n    }\n    bool _2889 = _2840 > 3;\n    bool _2896;\n    if (_2889)\n    {\n        _2896 = _2855 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2840)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2922 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2922;\n        if (_2922 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2947;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2947 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2947 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2966 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2947, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2977 = clamp((_2855 - (fa_shadow_split_at(param_7) - _2966)) / _2966, 0.0, 1.0);\n        if (_2977 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2840)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2998 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2998;\n                if (_2998 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2977);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2520 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2527;\n    if (!_2520)\n    {\n        _2527 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2527 = _2520;\n    }\n    if (_2527)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2540 = fa_light_texel(param);\n    float _2541 = _2540.x;\n    if (_2541 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2550 = int(_2541 + 0.5);\n    int param_1 = _2550;\n    vec4 _2554 = fa_light_texel(param_1);\n    int param_2 = _2550 + 1;\n    vec4 _2559 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2562 = _2554.y;\n    if (_2562 > 0.0)\n    {\n        float _2579 = 1.0 - smoothstep(0.75 * _2562, _2562, length(world - fa_shadows[27].xyz));\n        fade = _2579;\n        if (_2579 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2554.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2603 = (_2550 + 2) + (face * 6);\n    int param_4 = _2603;\n    int param_5 = _2603 + 1;\n    int param_6 = _2603 + 3;\n    vec4 _2617 = fa_light_texel(param_6);\n    int param_7 = _2603 + 4;\n    vec4 _2622 = fa_light_texel(param_7);\n    int param_8 = _2603 + 5;\n    vec4 _2627 = fa_light_texel(param_8);\n    float _2639 = _2627.x * max(dot(_2617, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2644 = clamp(dot(n, l), 0.0, 1.0);\n    float _2667 = clamp(dot(n, _2617.xyz), -1.0, 1.0);\n    float _2686 = min(sqrt(1.0 - (_2667 * _2667)) / max(abs(dot(n, world - lpos)) / max(dot(_2617, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2689 = _2559.y;\n    float _2691;\n    if (_2689 > 0.0)\n    {\n        _2691 = _2689;\n    }\n    else\n    {\n        _2691 = 1.5 * _2639;\n    }\n    vec4 _2711 = vec4(world + (n * (_2691 * sqrt(1.0 - (_2644 * _2644)))), 1.0);\n    float _2715 = dot(_2617, _2711);\n    float _2718 = _2627.y;\n    if (_2715 < _2718)\n    {\n        return 1.0;\n    }\n    vec2 _2733 = vec2(dot(fa_light_texel(param_4), _2711), dot(fa_light_texel(param_5), _2711)) / vec2(_2715);\n    float _2735 = _2733.x;\n    bool _2738 = _2735 < _2622.x;\n    bool _2747;\n    if (!_2738)\n    {\n        _2747 = _2735 > _2622.z;\n    }\n    else\n    {\n        _2747 = _2738;\n    }\n    bool _2756;\n    if (!_2747)\n    {\n        _2756 = _2733.y < _2622.y;\n    }\n    else\n    {\n        _2756 = _2747;\n    }\n    bool _2765;\n    if (!_2756)\n    {\n        _2765 = _2733.y > _2622.w;\n    }\n    else\n    {\n        _2765 = _2756;\n    }\n    if (_2765)\n    {\n        return 1.0;\n    }\n    float _2771 = _2559.x;\n    float _2773;\n    if (_2771 > 0.0)\n    {\n        _2773 = _2771;\n    }\n    else\n    {\n        _2773 = 1.5 * _2639;\n    }\n    vec2 param_9 = _2733;\n    vec4 param_10 = _2622;\n    float param_11 = _2715 - (_2773 * (1.0 + (0.5 * _2686)));\n    float param_12 = _2639;\n    float param_13 = 1.0;\n    float param_14 = _2627.z * 0.25;\n    float param_15 = (_2639 * min(_2686, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2718, _2627.z);\n    int param_17 = int(_2554.z + 0.5);\n    float param_18 = _2554.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4073 = fa_lm.z > 0.5;\n    bool _4079;\n    if (_4073)\n    {\n        int param = li;\n        _4079 = fa_light_baked(param);\n    }\n    else\n    {\n        _4079 = _4073;\n    }\n    if (_4079)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4103 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5195 = _4103.color;\n    float _5197 = _4103.shadow;\n    if ((_4103.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4103.direction;\n        float _4117 = fa_shadow_factor(param_5, param_6);\n        _5197 = _4117;\n        _5195 *= _4117;\n    }\n    else\n    {\n        bool _4128 = _4103.type != 0;\n        bool _4134;\n        if (_4128)\n        {\n            _4134 = _4103.attenuation > 0.0;\n        }\n        else\n        {\n            _4134 = _4128;\n        }\n        if (_4134)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4103.direction;\n            float _4153 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5197 = _4153;\n            _5195 *= _4153;\n        }\n    }\n    return LightSample(_4103.direction, _5195, _4103.attenuation, _5197, _4103._distance, _4103.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3022 = int(fa_shadows[25].x + 0.5);\n    float _3032 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3037 = _3022 > 0;\n    bool _3046;\n    if (_3037)\n    {\n        int param = _3022 - 1;\n        _3046 = _3032 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3046 = _3037;\n    }\n    if (_3046)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3052 = _3022 > 1;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3032 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3065 = _3022 > 2;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3032 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3078 = _3022 > 3;\n        bool _3085;\n        if (_3078)\n        {\n            _3085 = _3032 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3085 = _3078;\n        }\n        if (_3085)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4904 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4904 = -_4904;\n    }\n    vec3 _4539 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing);\n    Surface _4547 = fa_standard_surface(param_1);\n    vec3 _4943 = _4547.albedo;\n    float _4944 = _4547.alpha;\n    vec3 _4945 = _4547.normal;\n    float _4946 = _4547.metallic;\n    float _4947 = _4547.roughness;\n    float _4948 = _4547.occlusion;\n    vec3 _4949 = _4547.emission;\n    float _4950 = _4547.clearcoat;\n    float _4951 = _4547.clearcoat_roughness;\n    vec3 _4952 = _4547.sheen_color;\n    float _4953 = _4547.sheen_roughness;\n    float _4954 = _4547.anisotropy;\n    float _4955 = _4547.anisotropy_rotation;\n    float _4956 = _4547.specular;\n    float _4957 = _4547.ior;\n    vec3 _4958 = _4547.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing);\n    Surface param_3 = _4547;\n    surface(param_2, param_3);\n    _4943 = param_3.albedo;\n    _4944 = param_3.alpha;\n    _4945 = param_3.normal;\n    _4946 = param_3.metallic;\n    _4947 = param_3.roughness;\n    _4948 = param_3.occlusion;\n    _4949 = param_3.emission;\n    _4950 = param_3.clearcoat;\n    _4951 = param_3.clearcoat_roughness;\n    _4952 = param_3.sheen_color;\n    _4953 = param_3.sheen_roughness;\n    _4954 = param_3.anisotropy;\n    _4955 = param_3.anisotropy_rotation;\n    _4956 = param_3.specular;\n    _4957 = param_3.ior;\n    _4958 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4904;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4943 = param_6;\n    _4945 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4943;\n    }\n    else\n    {\n        vec3 _4585 = _4945;\n        vec3 _4586 = normalize(_4585);\n        _4945 = _4586;\n        vec3 param_8 = _4586;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing);\n        Surface param_10 = Surface(_4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4605 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4605; ln++)\n        {\n            int param_12 = ln;\n            int _4618 = fa_cl_light(param_12);\n            bool _4621 = fa_lm.z > 0.5;\n            bool _4627;\n            if (_4621)\n            {\n                int param_13 = _4618;\n                _4627 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4627 = _4621;\n            }\n            if (_4627)\n            {\n                continue;\n            }\n            int param_14 = _4618;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _4904;\n            LightSample _4639 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _4904, fa_world_tangent, fa_uv, fa_vertex_color, _4539, gl_FrontFacing);\n            Surface param_18 = Surface(_4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958);\n            LightSample param_19 = _4639;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _4654 = result;\n    vec3 _4655 = _4654 + _4949;\n    result = _4655;\n    vec3 param_20 = _4655;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4664 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4671;\n    if (!_4664)\n    {\n        _4671 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4671 = _4664;\n    }\n    if (_4671)\n    {\n        vec3 _4680 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4686 = dot(_4680, fa_mesh_fs_params[9].xyz);\n        bool _4690 = fa_mesh_fs_params[9].w > 0.5;\n        float _4691;\n        if (_4690)\n        {\n            _4691 = _4686;\n        }\n        else\n        {\n            _4691 = length(_4680);\n        }\n        float _4703 = _4691 - fa_mesh_fs_params[8].x;\n        if (_4703 > 0.0)\n        {\n            float _4712 = fa_mesh_fs_params[7].w * _4703;\n            float tau = _4712 * _4712;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4728;\n                if (_4690)\n                {\n                    _4728 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4686);\n                }\n                else\n                {\n                    _4728 = fa_mesh_fs_params[0].y;\n                }\n                float _4749 = mix(_4728, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4691, 0.0, 1.0));\n                float _4753 = fa_world_pos.y - _4749;\n                float _4758 = _4749 - fa_mesh_fs_params[8].z;\n                float _4763 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4766 = _4758 <= 0.0;\n                bool _4767 = !_4766;\n                bool _4773;\n                if (_4767)\n                {\n                    _4773 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4773 = _4766;\n                }\n                float _4774;\n                if (_4773)\n                {\n                    _4774 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4774 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4758, 80.0));\n                }\n                bool _4801;\n                if (_4767)\n                {\n                    _4801 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4801 = _4766;\n                }\n                float _4802;\n                if (_4801)\n                {\n                    _4802 = fa_mesh_fs_params[8].y * _4758;\n                }\n                else\n                {\n                    _4802 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4758, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4827 = _4763 <= 0.0;\n                bool _4834;\n                if (!_4827)\n                {\n                    _4834 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4834 = _4827;\n                }\n                float _4835;\n                if (_4834)\n                {\n                    _4835 = fa_mesh_fs_params[8].y * _4763;\n                }\n                else\n                {\n                    _4835 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4763, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4862;\n                if (abs(_4753) < 0.001000000047497451305389404296875)\n                {\n                    _4862 = _4774;\n                }\n                else\n                {\n                    _4862 = (_4835 - _4802) / _4753;\n                }\n                tau += (_4703 * max(_4862, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4944);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_429",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
            "inst_name": "_2086",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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

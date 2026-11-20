{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4155[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1410 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1417;\n    if (!_1410)\n    {\n        _1417 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1417 = _1410;\n    }\n    bool _1425;\n    if (!_1417)\n    {\n        _1425 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1425 = _1417;\n    }\n    bool _1432;\n    if (!_1425)\n    {\n        _1432 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1432 = _1425;\n    }\n    bool _1439;\n    if (!_1432)\n    {\n        _1439 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1439 = _1432;\n    }\n    if (_1439)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1449 = vec4(world_pos, 1.0);\n    float _1455 = dot(fa_mesh_fs_params[16], _1449);\n    if (!(_1455 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1477 = vec2(dot(fa_mesh_fs_params[14], _1449), dot(fa_mesh_fs_params[15], _1449)) / vec2(_1455);\n    int _1481 = int(fa_mesh_fs_params[18].x);\n    int _1485 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1485) + clamp(int(floor(((_1477.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1485 - 1)) * _1481)) + clamp(int(floor(((_1477.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1481 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1561 = fa_cluster_texel(param);\n    return ivec2(int(_1561.x), int(_1561.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4964 = fa_cluster_lookup(param);\n    fa_cl_slot = _4964.x;\n    fa_cl_local = _4964.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5176 = fa_linear_to_srgb(param);\n        c = _5176;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5184 = fa_srgb_to_linear(param_1);\n            c = _5184;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _364;\n    if (i.front_facing)\n    {\n        _364 = i.world_normal;\n    }\n    else\n    {\n        _364 = -i.world_normal;\n    }\n    vec3 _388 = normalize(i.world_tangent.xyz - (_364 * dot(_364, i.world_tangent.xyz)));\n    vec3 _415 = normalize(((_388 * m.x) + ((cross(_364, _388) * i.world_tangent.w) * m.y)) + (_364 * m.z));\n    vec3 _418;\n    if (i.front_facing)\n    {\n        _418 = _415;\n    }\n    else\n    {\n        _418 = -_415;\n    }\n    return _418;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5215 = fa_tex_fix(param_2, param_3);\n    vec4 _6400 = base_t;\n    _6400.x = _5215.x;\n    _6400.y = _5215.y;\n    _6400.z = _5215.z;\n    base_t = _6400;\n    vec4 _5229 = (_6400 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6214 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5261 = fa_tex_fix(param_6, param_7);\n        vec3 _5264 = (_5261 * 2.0) - vec3(1.0);\n        vec2 _5269 = _5264.xy * fa_mesh_fs_params[6].x;\n        vec3 _6408 = _5264;\n        _6408.x = _5269.x;\n        _6408.y = _5269.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6408;\n        _6214 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5297 = fa_tex_fix(param_12, param_13);\n    vec4 _6411 = mrt;\n    _6411.x = _5297.x;\n    _6411.y = _5297.y;\n    _6411.z = _5297.z;\n    mrt = _6411;\n    vec4 _5325 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5325.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5336 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5366 = fa_tex_fix(param_20, param_21);\n    float _6219 = fa_mesh_fs_params[20].x;\n    float _6220 = fa_mesh_fs_params[20].y;\n    float _6223 = fa_mesh_fs_params[20].z;\n    float _6222 = fa_mesh_fs_params[21].w;\n    float _6225 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6219 *= _5336.y;\n            _6220 *= _5336.z;\n            _6222 *= _5325.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6223 *= mrt.x;\n            _6225 *= mrt.w;\n        }\n    }\n    return Surface(_5229.xyz, _5229.w, _6214, clamp(fa_mesh_fs_params[5].x * _5297.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5297.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5336.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5366), _6219, _6220, fa_mesh_fs_params[21].xyz, _6222, _6223, fa_mesh_fs_params[20].w, _6225, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1641 = rect.zw - rect.xy;\n    vec2 _1645 = _1641 * atlas;\n    vec2 _1649 = ddx * _1645;\n    vec2 _1653 = ddy * _1645;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1641), clamp(0.5 * log2(max(max(dot(_1649, _1649), dot(_1653, _1653)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1686 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1693;\n    if (!_1686)\n    {\n        _1693 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1693 = _1686;\n    }\n    if (_1693)\n    {\n        return;\n    }\n    vec3 _1699 = dFdx(world_pos);\n    vec3 _1702 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1706 = fa_cluster_texel(param);\n    int _1710 = int(_1706.w);\n    if (_1710 < 1)\n    {\n        return;\n    }\n    int _1720 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1720;\n    vec4 _1724 = fa_light_texel(param_1);\n    vec2 _1727 = _1724.yz;\n    int _1731 = int(_1724.w);\n    int param_2 = _1720 + 1;\n    vec4 _1736 = fa_light_texel(param_2);\n    float _1737 = _1736.x;\n    int _1743 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1747 = int(_1706.z);\n    vec3 _2012;\n    for (int k = 0; k < _1710; k++)\n    {\n        int _1760 = _1747 + k;\n        int param_3 = _1731 + (_1760 >> 2);\n        int _1777 = (_1720 + 2) + (int(fa_light_texel(param_3)[_1760 & 3]) * 7);\n        int param_4 = _1777 + 6;\n        vec4 _1782 = fa_light_texel(param_4);\n        if (((int(_1782.w + 0.5) >> _1743) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1777;\n        vec4 _1797 = fa_light_texel(param_5);\n        int param_6 = _1777 + 1;\n        vec4 _1802 = fa_light_texel(param_6);\n        int param_7 = _1777 + 2;\n        vec4 _1807 = fa_light_texel(param_7);\n        vec3 _1810 = _1797.xyz;\n        float _1815 = dot(_1810, world_pos) + _1797.w;\n        vec3 _1817 = _1802.xyz;\n        float _1822 = dot(_1817, world_pos) + _1802.w;\n        vec3 _1824 = _1807.xyz;\n        float _1829 = dot(_1824, world_pos) + _1807.w;\n        bool _1834 = abs(_1815) > 0.5;\n        bool _1842;\n        if (!_1834)\n        {\n            _1842 = abs(_1822) > 0.5;\n        }\n        else\n        {\n            _1842 = _1834;\n        }\n        bool _1850;\n        if (!_1842)\n        {\n            _1850 = abs(_1829) > 0.5;\n        }\n        else\n        {\n            _1850 = _1842;\n        }\n        if (_1850)\n        {\n            continue;\n        }\n        float _1865 = clamp(dot(geo_normal, normalize(_1824)) * _1782.z, 0.0, 1.0);\n        if (_1865 <= 0.0)\n        {\n            continue;\n        }\n        float _1885 = (clamp((0.5 - abs(_1829)) * 10.0, 0.0, 1.0) * _1865) * _1782.x;\n        vec2 _1893 = vec2(_1815 + 0.5, 0.5 - _1822);\n        vec2 _1903 = vec2(dot(_1810, _1699), dot(_1817, _1699));\n        vec2 _1913 = vec2(dot(_1810, _1702), dot(_1817, _1702));\n        int param_8 = _1777 + 5;\n        vec4 _1918 = fa_light_texel(param_8);\n        int param_9 = _1777 + 3;\n        vec4 _1923 = fa_light_texel(param_9);\n        int param_10 = _1777 + 4;\n        vec4 _1928 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1918.xyz;\n        bool _1938 = _1923.z > _1923.x;\n        if (_1938)\n        {\n            vec4 param_11 = _1923;\n            vec2 param_12 = _1893;\n            vec2 param_13 = _1727;\n            vec2 param_14 = _1903;\n            vec2 param_15 = _1913;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1737 > 0.5) && (_1737 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1964 = fa_dc_to_linear(param_16);\n                vec4 _6294 = tx;\n                _6294.x = _1964.x;\n                _6294.y = _1964.y;\n                _6294.z = _1964.z;\n                tx = _6294;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1885 * tex_a) * _1918.w, 0.0, 1.0)));\n        if (_1928.z > _1928.x)\n        {\n            vec4 param_17 = _1928;\n            vec2 param_18 = _1893;\n            vec2 param_19 = _1727;\n            vec2 param_20 = _1903;\n            vec2 param_21 = _1913;\n            vec4 _2008 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1737 > 1.5)\n            {\n                vec3 param_22 = _2008.xyz;\n                vec3 _2018 = fa_dc_to_srgb(param_22);\n                _2012 = _2018;\n            }\n            else\n            {\n                _2012 = _2008.xyz;\n            }\n            vec3 _2027 = (_2012 * 2.0) - vec3(1.0);\n            vec2 _2032 = _2027.xy * _1782.y;\n            vec3 _2054 = (normalize(_1810) * _2032.x) + (normalize(_1817) * _2032.y);\n            vec3 _2057 = normalize(normal);\n            normal = normalize(mix(_2057, normalize((_2057 * max(_2027.z, 0.0500000007450580596923828125)) + (_2054 - (_2057 * dot(_2057, _2054)))), vec3(clamp(_1885 * (_1938 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3252 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3252;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3862 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _3867 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3862 > 0.0005000000237487256526947021484375)\n    {\n        if (_3867)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3862;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3862;\n        }\n    }\n    bool _3918 = fa_mesh_fs_params[40].w > 0.0;\n    if (_3918)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _3949 = fa_mesh_fs_params[45].w > 0.0;\n    if (_3949)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_3867 || _3918) || _3949)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4081 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4088 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4091 = int(_4081);\n    int _4094 = int(_4088);\n    float _4104 = _4088 - float(_4094);\n    int _4159 = (_4091 * 9) + _4094;\n    int _4179 = ((_4091 + 1) * 9) + _4094;\n    return mix(mix(_4155[_4159], _4155[_4159 + 1], _4104), mix(_4155[_4179], _4155[_4179 + 1], _4104), _4081 - float(_4091));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6073 = false;\n    float _6074 = 1.0;\n    float _6075 = 1.0;\n    float _6076 = 1.0;\n    float _6077 = 0.0;\n    float _6078 = 0.0;\n    float _6079 = 0.0;\n    float _6080 = 0.0;\n    float _6082 = 1.0;\n    bool _6083 = false;\n    vec3 _6084 = vec3(0.0);\n    float _6085 = 1.0;\n    float _6086 = 1.0;\n    float _6087 = 1.0;\n    float _6088 = 0.0;\n    float _6089 = 0.0;\n    vec3 _6090 = vec3(1.0, 0.0, 0.0);\n    vec3 _6091 = vec3(0.0, 0.0, 1.0);\n    float _6092 = 1.0;\n    float _6093 = 1.0;\n    float _4230 = clamp(s.specular, 0.0, 1.0);\n    float _4234 = clamp(s.ior, 1.0, 3.0);\n    bool _4239 = (_4230 != 1.0) || (_4234 != 1.5);\n    bool _4248;\n    if (!_4239)\n    {\n        _4248 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4248 = _4239;\n    }\n    if (_4248)\n    {\n        float _4256 = (_4234 - 1.0) / (_4234 + 1.0);\n        f0 = mix(min(vec3(_4256 * _4256) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4230, s.albedo, vec3(metallic));\n        _6074 = mix(_4230, 1.0, metallic);\n        _6073 = true;\n    }\n    float _4283 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4283 > 0.0)\n    {\n        float _4291 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6077 = _4283;\n        _6078 = _4291;\n        float _4298 = _4291 * _4291;\n        _6079 = _4298;\n        _6080 = _4298 * _4298;\n        float _4310 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6082 = _4310;\n        _6075 = 1.0 - (_4283 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4310, 0.0, 1.0), 5.0))));\n        _6073 = true;\n    }\n    vec3 _4329 = max(s.sheen_color, vec3(0.0));\n    float _4338 = max(_4329.x, max(_4329.y, _4329.z));\n    if (_4338 > 0.0)\n    {\n        float _4346 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6083 = true;\n        _6084 = _4329;\n        _6085 = _4346;\n        _6086 = _4346 * _4346;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4346;\n        float _4363 = fa_sheen_albedo(param, param_1);\n        _6088 = _4363;\n        _6087 = 1.0 - min(_4338 * _4363, 1.0);\n        _6073 = true;\n    }\n    _6076 = _6075 * _6087;\n    float _4382 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4382 != 0.0)\n    {\n        vec3 _4397 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4397;\n        if (dot(_4397, _4397) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4409 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4409.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4409.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4409.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4413 = t;\n        vec3 _4414 = normalize(_4413);\n        t = _4414;\n        vec3 _4439 = normalize((_4414 * cos(s.anisotropy_rotation)) + ((cross(n, _4414) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6090 = _4439;\n        _6091 = cross(n, _4439);\n        float _4449 = roughness * roughness;\n        float _4455 = mix(_4449, 1.0, _4382 * _4382);\n        bool _4457 = _4382 > 0.0;\n        _6092 = _4457 ? _4455 : _4449;\n        _6093 = _4457 ? _4449 : _4455;\n        _6089 = _4382;\n        _6073 = true;\n    }\n    return FaLayers(_6073, _6074, _6075, _6076, _6077, _6078, _6079, _6080, i.world_normal, _6082, _6083, _6084, _6085, _6086, _6087, _6088, _6089, _6090, _6091, _6092, _6093);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4013 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4016 = _4013.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4016 * _4016, exp2((-9.27999973297119140625) * ndv)) * _4016) + _4013.y)) + _4013.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3272 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3275 = _3272.x;\n    float _3277 = _3272.z;\n    vec2 e = vec2(_3275, _3277);\n    if (_3272.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3277)) * ((_3275 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3275)) * ((_3277 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3324;\n    if (lv == 0)\n    {\n        _3324 = 0.0;\n    }\n    else\n    {\n        _3324 = res + 2.0;\n    }\n    float _3334;\n    if (lv == 0)\n    {\n        _3334 = 0.0;\n    }\n    else\n    {\n        _3334 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3324, _3334)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3379;\n    if (res > 64.5)\n    {\n        _3379 = 5.0;\n    }\n    else\n    {\n        _3379 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3394 = clamp(rough, 0.0, 1.0) * (_3379 - 1.0);\n    int _3401 = int(min(floor(_3394), _3379 - 2.0));\n    float _3406 = _3394 - float(_3401);\n    vec3 param = d;\n    vec2 _3410 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3401;\n    vec2 param_4 = _3410;\n    vec3 _3420 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3406 < 0.00200000009499490261077880859375)\n    {\n        return _3420;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3401 + 1;\n    vec2 param_8 = _3410;\n    return mix(_3420, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3406));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3490 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3497 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3504 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3510 = dot(bx.xyz, d);\n    float _3514 = dot(by.xyz, d);\n    float _3518 = dot(bz.xyz, d);\n    float _3524;\n    if (_3510 > 9.9999999747524270787835121154785e-07)\n    {\n        _3524 = (1.0 - _3490) / _3510;\n    }\n    else\n    {\n        float _3538;\n        if (_3510 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3538 = ((-1.0) - _3490) / _3510;\n        }\n        else\n        {\n            _3538 = 1000000015047466219876688855040.0;\n        }\n        _3524 = _3538;\n    }\n    float tx = _3524;\n    float _3555;\n    if (_3514 > 9.9999999747524270787835121154785e-07)\n    {\n        _3555 = (1.0 - _3497) / _3514;\n    }\n    else\n    {\n        float _3568;\n        if (_3514 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3568 = ((-1.0) - _3497) / _3514;\n        }\n        else\n        {\n            _3568 = 1000000015047466219876688855040.0;\n        }\n        _3555 = _3568;\n    }\n    float ty = _3555;\n    float _3584;\n    if (_3518 > 9.9999999747524270787835121154785e-07)\n    {\n        _3584 = (1.0 - _3504) / _3518;\n    }\n    else\n    {\n        float _3597;\n        if (_3518 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3597 = ((-1.0) - _3504) / _3518;\n        }\n        else\n        {\n            _3597 = 1000000015047466219876688855040.0;\n        }\n        _3584 = _3597;\n    }\n    float _3609 = tx;\n    float _3612 = (_3609 > 0.0) ? _3609 : 1000000015047466219876688855040.0;\n    tx = _3612;\n    float _3613 = ty;\n    float _3616 = (_3613 > 0.0) ? _3613 : 1000000015047466219876688855040.0;\n    ty = _3616;\n    float _3626 = min(_3612, min(_3616, (_3584 > 0.0) ? _3584 : 1000000015047466219876688855040.0));\n    if (_3626 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3642 = (fa_world_pos + (d * _3626)) - posw.xyz;\n    vec3 _3647;\n    if (dot(_3642, _3642) > 1.0000000133514319600180897396058e-10)\n    {\n        _3647 = normalize(_3642);\n    }\n    else\n    {\n        _3647 = d;\n    }\n    return _3647;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3693 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 outc = vec3(0.0);\n    if (_3693 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[39].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3722 = rough * rough;\n            float _3753 = 0.60000002384185791015625 * _3722;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3722)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3753, 0.0500000007450580596923828125 + _3753, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3722 * 0.60000002384185791015625));\n        }\n        outc = base * _3693;\n    }\n    if (fa_mesh_fs_params[40].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[40];\n        vec4 param_5 = fa_mesh_fs_params[41];\n        vec4 param_6 = fa_mesh_fs_params[42];\n        vec4 param_7 = fa_mesh_fs_params[43];\n        vec4 param_8 = fa_mesh_fs_params[44];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3812 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3812 * fa_mesh_fs_params[40].w);\n    }\n    if (fa_mesh_fs_params[45].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[45];\n        vec4 param_12 = fa_mesh_fs_params[46];\n        vec4 param_13 = fa_mesh_fs_params[47];\n        vec4 param_14 = fa_mesh_fs_params[48];\n        vec4 param_15 = fa_mesh_fs_params[49];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3844 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3844 * fa_mesh_fs_params[45].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4490;\n        if (L.aniso >= 0.0)\n        {\n            _4490 = L.b;\n        }\n        else\n        {\n            _4490 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4490, v), _4490), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4523 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4523.x) + (vec3(L.f90) * _4523.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4578 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4578.x) + _4578.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4055 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4055.x) + vec3(_4055.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4607 = clamp(s.metallic, 0.0, 1.0);\n    float _4611 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4618 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4607));\n    vec3 f0 = _4618;\n    vec3 _4622 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4622;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4607;\n    float param_5 = _4611;\n    vec3 param_6 = _4618;\n    FaLayers _4639 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4639.on)\n    {\n        FaLayers param_7 = _4639;\n        vec3 param_8 = _4622;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4611;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _4622;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _4611;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4934;\n    if (fa_lm.z > 0.5)\n    {\n        _4934 = 0.0;\n    }\n    else\n    {\n        _4934 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4945 = _4934 < 1.0;\n    bool _4951;\n    if (_4945)\n    {\n        int param = li;\n        _4951 = fa_light_baked(param);\n    }\n    else\n    {\n        _4951 = _4945;\n    }\n    return _4951 ? _4934 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _660 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _673 = (c - (ru * hx)) - p;\n        vec3 _679 = ru * (2.0 * hx);\n        float _685 = max(dot(_679, _679), 9.9999999392252902907785028219223e-09);\n        float _689 = dot(_673, _679);\n        float t = clamp((-_689) / _685, 0.0, 1.0);\n        if (_660)\n        {\n            float _704 = dot(r, _679);\n            float _710 = _685 - (_704 * _704);\n            if (abs(_710) > (9.9999997473787516355514526367188e-06 * _685))\n            {\n                t = clamp(((dot(r, _673) * _704) - _689) / _710, 0.0, 1.0);\n            }\n        }\n        return (p + _673) + (_679 * t);\n    }\n    vec3 q = p;\n    float _742 = dot(r, axis);\n    bool _750;\n    if (_660)\n    {\n        _750 = abs(_742) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _750 = _660;\n    }\n    if (_750)\n    {\n        float _760 = dot(c - p, axis) / _742;\n        if (_760 > 0.0)\n        {\n            q = p + (r * _760);\n        }\n    }\n    vec3 _773 = q - c;\n    vec2 xy = vec2(dot(_773, ru), dot(_773, uu));\n    if (shape > 0.5)\n    {\n        float _788 = length(xy);\n        if (_788 > hx)\n        {\n            xy *= (hx / _788);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _430 = abs(d);\n    float _432 = _430.x;\n    float _434 = _430.y;\n    bool _435 = _432 >= _434;\n    bool _443;\n    if (_435)\n    {\n        _443 = _432 >= _430.z;\n    }\n    else\n    {\n        _443 = _435;\n    }\n    int _444;\n    if (_443)\n    {\n        _444 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _459;\n        if (_434 >= _430.z)\n        {\n            _459 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _459 = (d.z > 0.0) ? 4 : 5;\n        }\n        _444 = _459;\n    }\n    return _444;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _580 = dot(d, right);\n    float _584 = dot(d, up);\n    float _595;\n    if (((_580 * _580) + (_584 * _584)) > 1.0000000133514319600180897396058e-10)\n    {\n        _595 = atan(_584, _580) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _595 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_595 - floor(_595)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _826 = fa_light_base(param);\n    bool _830 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _826;\n    vec4 _834 = fa_light_texel(param_1);\n    int param_2 = _826 + 1;\n    vec4 _839 = fa_light_texel(param_2);\n    float _842 = _839.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _854 = _830 && (_842 > 2.5);\n    fa_light_is_area = _854;\n    bool _856 = _842 < 0.5;\n    vec3 l;\n    if (_856)\n    {\n        l = normalize(_834.xyz);\n        if (_830)\n        {\n            int param_3 = _826 + 6;\n            vec4 _870 = fa_light_texel(param_3);\n            if (_870.z > 0.5)\n            {\n                int param_4 = _826 + 4;\n                vec4 _880 = fa_light_texel(param_4);\n                int param_5 = _826 + 5;\n                vec4 _885 = fa_light_texel(param_5);\n                vec2 param_6 = _870.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _880.xyz) * _880.w, (-dot(world_pos, _885.xyz)) * _885.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _915 = _834.xyz;\n        vec3 _917 = _915 - world_pos;\n        vec3 to_light = _917;\n        float _920 = length(_917);\n        float reach = _920;\n        bool front = true;\n        if (_854)\n        {\n            int param_8 = _826 + 7;\n            reach = max(_920 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _826 + 4;\n            vec4 _944 = fa_light_texel(param_9);\n            int param_10 = _826 + 5;\n            vec4 _949 = fa_light_texel(param_10);\n            int param_11 = _826 + 6;\n            vec4 _954 = fa_light_texel(param_11);\n            float _955 = _954.w;\n            int param_12 = _826 + 2;\n            vec3 _962 = normalize(fa_light_texel(param_12).xyz);\n            bool _964 = _955 > 1.5;\n            bool _972;\n            if (!_964)\n            {\n                _972 = dot(_962, to_light) < 0.0;\n            }\n            else\n            {\n                _972 = _964;\n            }\n            front = _972;\n            vec3 r = vec3(0.0);\n            vec3 _981 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _985 = dot(n, n) > 0.5;\n            bool _993;\n            if (_985)\n            {\n                _993 = dot(_981, _981) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _993 = _985;\n            }\n            if (_993)\n            {\n                r = reflect(-normalize(_981), normalize(n));\n            }\n            vec3 param_13 = _915;\n            vec3 param_14 = _962;\n            vec3 param_15 = _944.xyz;\n            vec3 param_16 = _949.xyz;\n            float param_17 = _944.w;\n            float param_18 = _949.w;\n            float param_19 = _955;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1029 = length(to_light);\n        dist = _1029;\n        l = to_light / vec3(max(_1029, 9.9999997473787516355514526367188e-05));\n        float _1043 = reach / max(_834.w, 0.001000000047497451305389404296875);\n        float _1049 = clamp(1.0 - (_1043 * _1043), 0.0, 1.0);\n        float _1051;\n        if (front)\n        {\n            _1051 = _1049 * _1049;\n        }\n        else\n        {\n            _1051 = 0.0;\n        }\n        atten = _1051;\n        bool _1062 = _842 < 2.5;\n        if ((_842 > 1.5) && _1062)\n        {\n            int param_22 = _826 + 2;\n            vec4 _1070 = fa_light_texel(param_22);\n            float _1080 = _1070.w;\n            int param_23 = _826 + 3;\n            vec4 _1085 = fa_light_texel(param_23);\n            float _1086 = _1085.x;\n            float cos_inner = _1086;\n            if (_1086 > 1.5)\n            {\n                cos_inner = mix(_1080, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1080, cos_inner, dot(-l, normalize(_1070.xyz)));\n        }\n        if (_830 && (_842 < 1.5))\n        {\n            int param_24 = _826 + 6;\n            vec4 _1110 = fa_light_texel(param_24);\n            if (_1110.z > 0.5)\n            {\n                vec3 _1118 = -to_light;\n                int param_25 = _826 + 4;\n                int param_26 = _826 + 5;\n                vec3 _1132 = fa_light_texel(param_25).xyz;\n                vec3 _1136 = fa_light_texel(param_26).xyz;\n                vec3 _1145 = vec3(dot(_1118, _1132), dot(_1118, _1136), dot(_1118, cross(_1132, _1136)));\n                vec3 param_27 = _1145;\n                int _1149 = fa_cube_face(param_27);\n                int param_28 = _1149;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1176 = vec2(dot(_1145, cross(param_29, param_30)), dot(_1145, param_30)) / vec2(max(dot(_1145, param_29), 9.9999997473787516355514526367188e-05));\n                int _1180 = _1149 / 3;\n                vec2 param_31 = _1110.xy + (vec2(float(_1149 - (_1180 * 3)), float(_1180)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1176.x), 0.5 - (0.5 * _1176.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _826 + 7;\n            vec4 _1210 = fa_light_texel(param_33);\n            if (_1210.z > 0.5)\n            {\n                int param_34 = _826 + 2;\n                int param_35 = _826 + 4;\n                int param_36 = _826 + 5;\n                vec2 param_37 = _1210.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_830 && _1062)\n            {\n                int param_42 = _826 + 6;\n                vec4 _1257 = fa_light_texel(param_42);\n                int param_43 = _826 + 7;\n                vec4 _1262 = fa_light_texel(param_43);\n                bool _1265 = _1257.z > 0.5;\n                bool _1272;\n                if (!_1265)\n                {\n                    _1272 = _1262.z > 0.5;\n                }\n                else\n                {\n                    _1272 = _1265;\n                }\n                if (_1272)\n                {\n                    int param_44 = _826 + 2;\n                    vec4 _1279 = fa_light_texel(param_44);\n                    vec3 _1283 = normalize(_1279.xyz);\n                    int param_45 = _826 + 4;\n                    vec4 _1288 = fa_light_texel(param_45);\n                    int param_46 = _826 + 5;\n                    vec4 _1293 = fa_light_texel(param_46);\n                    if (_1265)\n                    {\n                        vec3 _1301 = -to_light;\n                        float _1308 = _1279.w;\n                        float _1324 = 0.5 / max(dot(_1301, _1283) * (sqrt(max(1.0 - (_1308 * _1308), 0.0)) / max(_1308, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1257.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1301, _1288.xyz) * _1324), 0.5 - (dot(_1301, _1293.xyz) * _1324));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1262.z > 0.5)\n                    {\n                        vec2 param_49 = _1262.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1283;\n                        vec3 param_52 = _1288.xyz;\n                        vec3 param_53 = _1293.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6061 = _839.xyz * atten;\n    if (_830)\n    {\n        _6061 *= fa_light_tint;\n    }\n    int _1392;\n    if (_856)\n    {\n        _1392 = 0;\n    }\n    else\n    {\n        _1392 = ((_842 > 1.5) && (_842 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6061, atten, 1.0, dist, _1392);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2129;\n    if (i == 0)\n    {\n        _2129 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2145;\n        if (i == 1)\n        {\n            _2145 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2153;\n            if (i == 2)\n            {\n                _2153 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2153 = fa_shadows[24].w;\n            }\n            _2145 = _2153;\n        }\n        _2129 = _2145;\n    }\n    return _2129;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2186 = fa_shadow_depth(param, param_1);\n    float _2190;\n    if (conv.x < 0.5)\n    {\n        _2190 = _2186;\n    }\n    else\n    {\n        _2190 = (conv.y * conv.z) / (conv.z - (_2186 * (conv.z - conv.y)));\n    }\n    return _2190;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2117 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2117), sin(_2117)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2236 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2245;\n        if (k < 0.0)\n        {\n            _2245 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        float _2265 = clamp((_2245 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2236;\n            vec2 _2284 = fa_shadow_vogel(param_3, param_4, param_5) * _2265;\n            vec2 param_6 = uv + (_2284 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2296 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2296 < (zr - (length(_2284) * plane)))\n            {\n                sum += _2296;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2322 = sum / cnt;\n        float _2332;\n        if (k < 0.0)\n        {\n            _2332 = (-k) / max(_2322, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2332 = k;\n        }\n        radius = clamp(((max(zr - _2322, 0.0) * unit) * _2332) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2354 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2354; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2354;\n        float param_11 = _2236;\n        vec2 _2373 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2373 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2373) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2354);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2415 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2420 = clamp(dot(n, l), 0.0, 1.0);\n    float _2426 = sqrt(1.0 - (_2420 * _2420));\n    float _2433 = min(_2426 / max(_2420, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2426)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2415);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2415;\n    float param_5 = _2415 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2415;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2893)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2975 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2975;\n        if (_2975 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3000;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3000 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3000 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3019 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3000, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3030 = clamp((_2908 - (fa_shadow_split_at(param_7) - _3019)) / _3019, 0.0, 1.0);\n        if (_3030 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2893)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3051 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3051;\n                if (_3051 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3030);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4678 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4685;\n    if (!_4678)\n    {\n        _4685 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4685 = _4678;\n    }\n    if (_4685)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4698 = fa_light_texel(param);\n    float _4699 = _4698.y;\n    float len = _4699;\n    if (_4699 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4711 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4721 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4711);\n    if (_4721 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4727 = len;\n    float _4730 = min(_4727, 0.89999997615814208984375 * dist);\n    len = _4730;\n    float _4735 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4711);\n    float _4740 = _4735 + (0.5 * _4730);\n    vec3 _4746 = world + (gn * _4735);\n    float _4748 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4812;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4763 = (float(k) + _4748) * 0.083333335816860198974609375;\n        vec3 _4771 = _4746 + (l * (_4763 * len));\n        vec4 _4777 = vec4(_4771, 1.0);\n        float _4783 = dot(fa_mesh_fs_params[28], _4777);\n        if (_4783 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4803 = vec2(dot(fa_mesh_fs_params[26], _4777), dot(fa_mesh_fs_params[27], _4777)) / vec2(_4783);\n        float _4807 = _4803.x * 0.5;\n        float _4808 = _4807 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4812 = (_4803.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4812 = 0.5 - (_4803.y * 0.5);\n        }\n        bool _4828 = _4808 < 0.0;\n        bool _4835;\n        if (!_4828)\n        {\n            _4835 = _4808 >= 1.0;\n        }\n        else\n        {\n            _4835 = _4828;\n        }\n        bool _4842;\n        if (!_4835)\n        {\n            _4842 = _4812 < 0.0;\n        }\n        else\n        {\n            _4842 = _4835;\n        }\n        bool _4849;\n        if (!_4842)\n        {\n            _4849 = _4812 >= 1.0;\n        }\n        else\n        {\n            _4849 = _4842;\n        }\n        if (_4849)\n        {\n            break;\n        }\n        vec4 _4868 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4808, _4812) * fa_mesh_fs_params[24].zw), 0);\n        if (_4868.w < 0.5)\n        {\n            continue;\n        }\n        float _4887 = (dot(fa_mesh_fs_params[29].xyz, _4771) + fa_mesh_fs_params[29].w) - _4868.x;\n        if ((_4887 > _4735) && (_4887 < _4740))\n        {\n            occ = max(occ, (1.0 - (_4763 * _4763)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4808, 0.5 - _4807), min(_4812, 1.0 - _4812))));\n        }\n    }\n    return 1.0 - (occ * _4721);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4990 = fa_baked_keep(param);\n    if (_4990 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5016 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6194 = _5016.color;\n    float _6195 = _5016.attenuation;\n    float _6196 = _5016.shadow;\n    bool _5019 = _5016.type == 0;\n    if (_5019 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5016.direction;\n        float _5030 = fa_shadow_factor(param_5, param_6);\n        _6196 = _5030;\n        _6194 *= _5030;\n    }\n    else\n    {\n        bool _5041 = _5016.type != 0;\n        bool _5047;\n        if (_5041)\n        {\n            _5047 = _6195 > 0.0;\n        }\n        else\n        {\n            _5047 = _5041;\n        }\n        if (_5047)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5016.direction;\n            float _5066 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6196 = _5066;\n            _6194 *= _5066;\n        }\n    }\n    bool _5076 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5082;\n    if (_5076)\n    {\n        _5082 = _6195 > 0.0;\n    }\n    else\n    {\n        _5082 = _5076;\n    }\n    if (_5082)\n    {\n        float _5089;\n        if (_5019)\n        {\n            _5089 = 1000000000.0;\n        }\n        else\n        {\n            _5089 = _5016._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5016.direction;\n        float param_18 = _5089;\n        float _5107 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6196 *= _5107;\n        _6194 *= _5107;\n    }\n    float _5120 = _6195;\n    float _5121 = _5120 * _4990;\n    _6195 = _5121;\n    vec3 _5125 = _6194;\n    vec3 _5126 = _5125 * _4990;\n    _6194 = _5126;\n    return LightSample(_5016.direction, _5126, _5121, _6196, _5016._distance, _5016.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3075 = int(fa_shadows[25].x + 0.5);\n    float _3085 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3090 = _3075 > 0;\n    bool _3099;\n    if (_3090)\n    {\n        int param = _3075 - 1;\n        _3099 = _3085 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3099 = _3090;\n    }\n    if (_3099)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3105 = _3075 > 1;\n        bool _3112;\n        if (_3105)\n        {\n            _3112 = _3085 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3112 = _3105;\n        }\n        if (_3112)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3118 = _3075 > 2;\n        bool _3125;\n        if (_3118)\n        {\n            _3125 = _3085 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3125 = _3118;\n        }\n        if (_3125)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3131 = _3075 > 3;\n        bool _3138;\n        if (_3131)\n        {\n            _3138 = _3085 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3138 = _3131;\n        }\n        if (_3138)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5903 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5903 = -_5903;\n    }\n    vec3 _5543 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n    Surface _5551 = fa_standard_surface(param_1);\n    vec3 _5942 = _5551.albedo;\n    float _5943 = _5551.alpha;\n    vec3 _5944 = _5551.normal;\n    float _5945 = _5551.metallic;\n    float _5946 = _5551.roughness;\n    float _5947 = _5551.occlusion;\n    vec3 _5948 = _5551.emission;\n    float _5949 = _5551.clearcoat;\n    float _5950 = _5551.clearcoat_roughness;\n    vec3 _5951 = _5551.sheen_color;\n    float _5952 = _5551.sheen_roughness;\n    float _5953 = _5551.anisotropy;\n    float _5954 = _5551.anisotropy_rotation;\n    float _5955 = _5551.specular;\n    float _5956 = _5551.ior;\n    vec3 _5957 = _5551.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n    Surface param_3 = _5551;\n    surface(param_2, param_3);\n    _5942 = param_3.albedo;\n    _5943 = param_3.alpha;\n    _5944 = param_3.normal;\n    _5945 = param_3.metallic;\n    _5946 = param_3.roughness;\n    _5947 = param_3.occlusion;\n    _5948 = param_3.emission;\n    _5949 = param_3.clearcoat;\n    _5950 = param_3.clearcoat_roughness;\n    _5951 = param_3.sheen_color;\n    _5952 = param_3.sheen_roughness;\n    _5953 = param_3.anisotropy;\n    _5954 = param_3.anisotropy_rotation;\n    _5955 = param_3.specular;\n    _5956 = param_3.ior;\n    _5957 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5903;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5942 = param_6;\n    _5944 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5942;\n    }\n    else\n    {\n        vec3 _5589 = _5944;\n        vec3 _5590 = normalize(_5589);\n        _5944 = _5590;\n        vec3 param_8 = _5590;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n        Surface param_10 = Surface(_5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5609 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5609; ln++)\n        {\n            int param_12 = ln;\n            int _5622 = fa_cl_light(param_12);\n            int param_13 = _5622;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5622;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5903;\n            LightSample _5638 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n            Surface param_18 = Surface(_5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957);\n            LightSample param_19 = _5638;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5653 = result;\n    vec3 _5654 = _5653 + _5948;\n    result = _5654;\n    vec3 param_20 = _5654;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5663 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5670;\n    if (!_5663)\n    {\n        _5670 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5670 = _5663;\n    }\n    if (_5670)\n    {\n        vec3 _5679 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5685 = dot(_5679, fa_mesh_fs_params[9].xyz);\n        bool _5689 = fa_mesh_fs_params[9].w > 0.5;\n        float _5690;\n        if (_5689)\n        {\n            _5690 = _5685;\n        }\n        else\n        {\n            _5690 = length(_5679);\n        }\n        float _5702 = _5690 - fa_mesh_fs_params[8].x;\n        if (_5702 > 0.0)\n        {\n            float _5711 = fa_mesh_fs_params[7].w * _5702;\n            float tau = _5711 * _5711;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5727;\n                if (_5689)\n                {\n                    _5727 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5685);\n                }\n                else\n                {\n                    _5727 = fa_mesh_fs_params[0].y;\n                }\n                float _5748 = mix(_5727, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5690, 0.0, 1.0));\n                float _5752 = fa_world_pos.y - _5748;\n                float _5757 = _5748 - fa_mesh_fs_params[8].z;\n                float _5762 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5765 = _5757 <= 0.0;\n                bool _5766 = !_5765;\n                bool _5772;\n                if (_5766)\n                {\n                    _5772 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5772 = _5765;\n                }\n                float _5773;\n                if (_5772)\n                {\n                    _5773 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5773 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5757, 80.0));\n                }\n                bool _5800;\n                if (_5766)\n                {\n                    _5800 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5800 = _5765;\n                }\n                float _5801;\n                if (_5800)\n                {\n                    _5801 = fa_mesh_fs_params[8].y * _5757;\n                }\n                else\n                {\n                    _5801 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5757, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5826 = _5762 <= 0.0;\n                bool _5833;\n                if (!_5826)\n                {\n                    _5833 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5833 = _5826;\n                }\n                float _5834;\n                if (_5833)\n                {\n                    _5834 = fa_mesh_fs_params[8].y * _5762;\n                }\n                else\n                {\n                    _5834 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5762, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5861;\n                if (abs(_5752) < 0.001000000047497451305389404296875)\n                {\n                    _5861 = _5773;\n                }\n                else\n                {\n                    _5861 = (_5834 - _5801) / _5752;\n                }\n                tau += (_5702 * max(_5861, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5943);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_482",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2139",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
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
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4155[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1410 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1417;\n    if (!_1410)\n    {\n        _1417 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1417 = _1410;\n    }\n    bool _1425;\n    if (!_1417)\n    {\n        _1425 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1425 = _1417;\n    }\n    bool _1432;\n    if (!_1425)\n    {\n        _1432 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1432 = _1425;\n    }\n    bool _1439;\n    if (!_1432)\n    {\n        _1439 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1439 = _1432;\n    }\n    if (_1439)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1449 = vec4(world_pos, 1.0);\n    float _1455 = dot(fa_mesh_fs_params[16], _1449);\n    if (!(_1455 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1477 = vec2(dot(fa_mesh_fs_params[14], _1449), dot(fa_mesh_fs_params[15], _1449)) / vec2(_1455);\n    int _1481 = int(fa_mesh_fs_params[18].x);\n    int _1485 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1485) + clamp(int(floor(((_1477.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1485 - 1)) * _1481)) + clamp(int(floor(((_1477.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1481 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1561 = fa_cluster_texel(param);\n    return ivec2(int(_1561.x), int(_1561.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4964 = fa_cluster_lookup(param);\n    fa_cl_slot = _4964.x;\n    fa_cl_local = _4964.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5176 = fa_linear_to_srgb(param);\n        c = _5176;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5184 = fa_srgb_to_linear(param_1);\n            c = _5184;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _364;\n    if (i.front_facing)\n    {\n        _364 = i.world_normal;\n    }\n    else\n    {\n        _364 = -i.world_normal;\n    }\n    vec3 _388 = normalize(i.world_tangent.xyz - (_364 * dot(_364, i.world_tangent.xyz)));\n    vec3 _415 = normalize(((_388 * m.x) + ((cross(_364, _388) * i.world_tangent.w) * m.y)) + (_364 * m.z));\n    vec3 _418;\n    if (i.front_facing)\n    {\n        _418 = _415;\n    }\n    else\n    {\n        _418 = -_415;\n    }\n    return _418;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5215 = fa_tex_fix(param_2, param_3);\n    vec4 _6400 = base_t;\n    _6400.x = _5215.x;\n    _6400.y = _5215.y;\n    _6400.z = _5215.z;\n    base_t = _6400;\n    vec4 _5229 = (_6400 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6214 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5261 = fa_tex_fix(param_6, param_7);\n        vec3 _5264 = (_5261 * 2.0) - vec3(1.0);\n        vec2 _5269 = _5264.xy * fa_mesh_fs_params[6].x;\n        vec3 _6408 = _5264;\n        _6408.x = _5269.x;\n        _6408.y = _5269.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6408;\n        _6214 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5297 = fa_tex_fix(param_12, param_13);\n    vec4 _6411 = mrt;\n    _6411.x = _5297.x;\n    _6411.y = _5297.y;\n    _6411.z = _5297.z;\n    mrt = _6411;\n    vec4 _5325 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5325.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5336 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5366 = fa_tex_fix(param_20, param_21);\n    float _6219 = fa_mesh_fs_params[20].x;\n    float _6220 = fa_mesh_fs_params[20].y;\n    float _6223 = fa_mesh_fs_params[20].z;\n    float _6222 = fa_mesh_fs_params[21].w;\n    float _6225 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6219 *= _5336.y;\n            _6220 *= _5336.z;\n            _6222 *= _5325.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6223 *= mrt.x;\n            _6225 *= mrt.w;\n        }\n    }\n    return Surface(_5229.xyz, _5229.w, _6214, clamp(fa_mesh_fs_params[5].x * _5297.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5297.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5336.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5366), _6219, _6220, fa_mesh_fs_params[21].xyz, _6222, _6223, fa_mesh_fs_params[20].w, _6225, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1641 = rect.zw - rect.xy;\n    vec2 _1645 = _1641 * atlas;\n    vec2 _1649 = ddx * _1645;\n    vec2 _1653 = ddy * _1645;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1641), clamp(0.5 * log2(max(max(dot(_1649, _1649), dot(_1653, _1653)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1686 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1693;\n    if (!_1686)\n    {\n        _1693 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1693 = _1686;\n    }\n    if (_1693)\n    {\n        return;\n    }\n    vec3 _1699 = dFdx(world_pos);\n    vec3 _1702 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1706 = fa_cluster_texel(param);\n    int _1710 = int(_1706.w);\n    if (_1710 < 1)\n    {\n        return;\n    }\n    int _1720 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1720;\n    vec4 _1724 = fa_light_texel(param_1);\n    vec2 _1727 = _1724.yz;\n    int _1731 = int(_1724.w);\n    int param_2 = _1720 + 1;\n    vec4 _1736 = fa_light_texel(param_2);\n    float _1737 = _1736.x;\n    int _1743 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1747 = int(_1706.z);\n    vec3 _2012;\n    for (int k = 0; k < _1710; k++)\n    {\n        int _1760 = _1747 + k;\n        int param_3 = _1731 + (_1760 >> 2);\n        int _1777 = (_1720 + 2) + (int(fa_light_texel(param_3)[_1760 & 3]) * 7);\n        int param_4 = _1777 + 6;\n        vec4 _1782 = fa_light_texel(param_4);\n        if (((int(_1782.w + 0.5) >> _1743) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1777;\n        vec4 _1797 = fa_light_texel(param_5);\n        int param_6 = _1777 + 1;\n        vec4 _1802 = fa_light_texel(param_6);\n        int param_7 = _1777 + 2;\n        vec4 _1807 = fa_light_texel(param_7);\n        vec3 _1810 = _1797.xyz;\n        float _1815 = dot(_1810, world_pos) + _1797.w;\n        vec3 _1817 = _1802.xyz;\n        float _1822 = dot(_1817, world_pos) + _1802.w;\n        vec3 _1824 = _1807.xyz;\n        float _1829 = dot(_1824, world_pos) + _1807.w;\n        bool _1834 = abs(_1815) > 0.5;\n        bool _1842;\n        if (!_1834)\n        {\n            _1842 = abs(_1822) > 0.5;\n        }\n        else\n        {\n            _1842 = _1834;\n        }\n        bool _1850;\n        if (!_1842)\n        {\n            _1850 = abs(_1829) > 0.5;\n        }\n        else\n        {\n            _1850 = _1842;\n        }\n        if (_1850)\n        {\n            continue;\n        }\n        float _1865 = clamp(dot(geo_normal, normalize(_1824)) * _1782.z, 0.0, 1.0);\n        if (_1865 <= 0.0)\n        {\n            continue;\n        }\n        float _1885 = (clamp((0.5 - abs(_1829)) * 10.0, 0.0, 1.0) * _1865) * _1782.x;\n        vec2 _1893 = vec2(_1815 + 0.5, 0.5 - _1822);\n        vec2 _1903 = vec2(dot(_1810, _1699), dot(_1817, _1699));\n        vec2 _1913 = vec2(dot(_1810, _1702), dot(_1817, _1702));\n        int param_8 = _1777 + 5;\n        vec4 _1918 = fa_light_texel(param_8);\n        int param_9 = _1777 + 3;\n        vec4 _1923 = fa_light_texel(param_9);\n        int param_10 = _1777 + 4;\n        vec4 _1928 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1918.xyz;\n        bool _1938 = _1923.z > _1923.x;\n        if (_1938)\n        {\n            vec4 param_11 = _1923;\n            vec2 param_12 = _1893;\n            vec2 param_13 = _1727;\n            vec2 param_14 = _1903;\n            vec2 param_15 = _1913;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1737 > 0.5) && (_1737 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1964 = fa_dc_to_linear(param_16);\n                vec4 _6294 = tx;\n                _6294.x = _1964.x;\n                _6294.y = _1964.y;\n                _6294.z = _1964.z;\n                tx = _6294;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1885 * tex_a) * _1918.w, 0.0, 1.0)));\n        if (_1928.z > _1928.x)\n        {\n            vec4 param_17 = _1928;\n            vec2 param_18 = _1893;\n            vec2 param_19 = _1727;\n            vec2 param_20 = _1903;\n            vec2 param_21 = _1913;\n            vec4 _2008 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1737 > 1.5)\n            {\n                vec3 param_22 = _2008.xyz;\n                vec3 _2018 = fa_dc_to_srgb(param_22);\n                _2012 = _2018;\n            }\n            else\n            {\n                _2012 = _2008.xyz;\n            }\n            vec3 _2027 = (_2012 * 2.0) - vec3(1.0);\n            vec2 _2032 = _2027.xy * _1782.y;\n            vec3 _2054 = (normalize(_1810) * _2032.x) + (normalize(_1817) * _2032.y);\n            vec3 _2057 = normalize(normal);\n            normal = normalize(mix(_2057, normalize((_2057 * max(_2027.z, 0.0500000007450580596923828125)) + (_2054 - (_2057 * dot(_2057, _2054)))), vec3(clamp(_1885 * (_1938 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3252 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3252;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3862 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _3867 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3862 > 0.0005000000237487256526947021484375)\n    {\n        if (_3867)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3862;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3862;\n        }\n    }\n    bool _3918 = fa_mesh_fs_params[40].w > 0.0;\n    if (_3918)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _3949 = fa_mesh_fs_params[45].w > 0.0;\n    if (_3949)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_3867 || _3918) || _3949)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4081 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4088 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4091 = int(_4081);\n    int _4094 = int(_4088);\n    float _4104 = _4088 - float(_4094);\n    int _4159 = (_4091 * 9) + _4094;\n    int _4179 = ((_4091 + 1) * 9) + _4094;\n    return mix(mix(_4155[_4159], _4155[_4159 + 1], _4104), mix(_4155[_4179], _4155[_4179 + 1], _4104), _4081 - float(_4091));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6073 = false;\n    float _6074 = 1.0;\n    float _6075 = 1.0;\n    float _6076 = 1.0;\n    float _6077 = 0.0;\n    float _6078 = 0.0;\n    float _6079 = 0.0;\n    float _6080 = 0.0;\n    float _6082 = 1.0;\n    bool _6083 = false;\n    vec3 _6084 = vec3(0.0);\n    float _6085 = 1.0;\n    float _6086 = 1.0;\n    float _6087 = 1.0;\n    float _6088 = 0.0;\n    float _6089 = 0.0;\n    vec3 _6090 = vec3(1.0, 0.0, 0.0);\n    vec3 _6091 = vec3(0.0, 0.0, 1.0);\n    float _6092 = 1.0;\n    float _6093 = 1.0;\n    float _4230 = clamp(s.specular, 0.0, 1.0);\n    float _4234 = clamp(s.ior, 1.0, 3.0);\n    bool _4239 = (_4230 != 1.0) || (_4234 != 1.5);\n    bool _4248;\n    if (!_4239)\n    {\n        _4248 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4248 = _4239;\n    }\n    if (_4248)\n    {\n        float _4256 = (_4234 - 1.0) / (_4234 + 1.0);\n        f0 = mix(min(vec3(_4256 * _4256) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4230, s.albedo, vec3(metallic));\n        _6074 = mix(_4230, 1.0, metallic);\n        _6073 = true;\n    }\n    float _4283 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4283 > 0.0)\n    {\n        float _4291 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6077 = _4283;\n        _6078 = _4291;\n        float _4298 = _4291 * _4291;\n        _6079 = _4298;\n        _6080 = _4298 * _4298;\n        float _4310 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6082 = _4310;\n        _6075 = 1.0 - (_4283 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4310, 0.0, 1.0), 5.0))));\n        _6073 = true;\n    }\n    vec3 _4329 = max(s.sheen_color, vec3(0.0));\n    float _4338 = max(_4329.x, max(_4329.y, _4329.z));\n    if (_4338 > 0.0)\n    {\n        float _4346 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6083 = true;\n        _6084 = _4329;\n        _6085 = _4346;\n        _6086 = _4346 * _4346;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4346;\n        float _4363 = fa_sheen_albedo(param, param_1);\n        _6088 = _4363;\n        _6087 = 1.0 - min(_4338 * _4363, 1.0);\n        _6073 = true;\n    }\n    _6076 = _6075 * _6087;\n    float _4382 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4382 != 0.0)\n    {\n        vec3 _4397 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4397;\n        if (dot(_4397, _4397) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4409 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4409.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4409.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4409.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4413 = t;\n        vec3 _4414 = normalize(_4413);\n        t = _4414;\n        vec3 _4439 = normalize((_4414 * cos(s.anisotropy_rotation)) + ((cross(n, _4414) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6090 = _4439;\n        _6091 = cross(n, _4439);\n        float _4449 = roughness * roughness;\n        float _4455 = mix(_4449, 1.0, _4382 * _4382);\n        bool _4457 = _4382 > 0.0;\n        _6092 = _4457 ? _4455 : _4449;\n        _6093 = _4457 ? _4449 : _4455;\n        _6089 = _4382;\n        _6073 = true;\n    }\n    return FaLayers(_6073, _6074, _6075, _6076, _6077, _6078, _6079, _6080, i.world_normal, _6082, _6083, _6084, _6085, _6086, _6087, _6088, _6089, _6090, _6091, _6092, _6093);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4013 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4016 = _4013.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4016 * _4016, exp2((-9.27999973297119140625) * ndv)) * _4016) + _4013.y)) + _4013.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3272 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3275 = _3272.x;\n    float _3277 = _3272.z;\n    vec2 e = vec2(_3275, _3277);\n    if (_3272.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3277)) * ((_3275 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3275)) * ((_3277 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3324;\n    if (lv == 0)\n    {\n        _3324 = 0.0;\n    }\n    else\n    {\n        _3324 = res + 2.0;\n    }\n    float _3334;\n    if (lv == 0)\n    {\n        _3334 = 0.0;\n    }\n    else\n    {\n        _3334 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3324, _3334)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3379;\n    if (res > 64.5)\n    {\n        _3379 = 5.0;\n    }\n    else\n    {\n        _3379 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3394 = clamp(rough, 0.0, 1.0) * (_3379 - 1.0);\n    int _3401 = int(min(floor(_3394), _3379 - 2.0));\n    float _3406 = _3394 - float(_3401);\n    vec3 param = d;\n    vec2 _3410 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3401;\n    vec2 param_4 = _3410;\n    vec3 _3420 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3406 < 0.00200000009499490261077880859375)\n    {\n        return _3420;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3401 + 1;\n    vec2 param_8 = _3410;\n    return mix(_3420, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3406));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3490 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3497 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3504 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3510 = dot(bx.xyz, d);\n    float _3514 = dot(by.xyz, d);\n    float _3518 = dot(bz.xyz, d);\n    float _3524;\n    if (_3510 > 9.9999999747524270787835121154785e-07)\n    {\n        _3524 = (1.0 - _3490) / _3510;\n    }\n    else\n    {\n        float _3538;\n        if (_3510 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3538 = ((-1.0) - _3490) / _3510;\n        }\n        else\n        {\n            _3538 = 1000000015047466219876688855040.0;\n        }\n        _3524 = _3538;\n    }\n    float tx = _3524;\n    float _3555;\n    if (_3514 > 9.9999999747524270787835121154785e-07)\n    {\n        _3555 = (1.0 - _3497) / _3514;\n    }\n    else\n    {\n        float _3568;\n        if (_3514 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3568 = ((-1.0) - _3497) / _3514;\n        }\n        else\n        {\n            _3568 = 1000000015047466219876688855040.0;\n        }\n        _3555 = _3568;\n    }\n    float ty = _3555;\n    float _3584;\n    if (_3518 > 9.9999999747524270787835121154785e-07)\n    {\n        _3584 = (1.0 - _3504) / _3518;\n    }\n    else\n    {\n        float _3597;\n        if (_3518 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3597 = ((-1.0) - _3504) / _3518;\n        }\n        else\n        {\n            _3597 = 1000000015047466219876688855040.0;\n        }\n        _3584 = _3597;\n    }\n    float _3609 = tx;\n    float _3612 = (_3609 > 0.0) ? _3609 : 1000000015047466219876688855040.0;\n    tx = _3612;\n    float _3613 = ty;\n    float _3616 = (_3613 > 0.0) ? _3613 : 1000000015047466219876688855040.0;\n    ty = _3616;\n    float _3626 = min(_3612, min(_3616, (_3584 > 0.0) ? _3584 : 1000000015047466219876688855040.0));\n    if (_3626 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3642 = (fa_world_pos + (d * _3626)) - posw.xyz;\n    vec3 _3647;\n    if (dot(_3642, _3642) > 1.0000000133514319600180897396058e-10)\n    {\n        _3647 = normalize(_3642);\n    }\n    else\n    {\n        _3647 = d;\n    }\n    return _3647;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3693 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 outc = vec3(0.0);\n    if (_3693 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[39].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3722 = rough * rough;\n            float _3753 = 0.60000002384185791015625 * _3722;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3722)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3753, 0.0500000007450580596923828125 + _3753, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3722 * 0.60000002384185791015625));\n        }\n        outc = base * _3693;\n    }\n    if (fa_mesh_fs_params[40].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[40];\n        vec4 param_5 = fa_mesh_fs_params[41];\n        vec4 param_6 = fa_mesh_fs_params[42];\n        vec4 param_7 = fa_mesh_fs_params[43];\n        vec4 param_8 = fa_mesh_fs_params[44];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3812 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3812 * fa_mesh_fs_params[40].w);\n    }\n    if (fa_mesh_fs_params[45].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[45];\n        vec4 param_12 = fa_mesh_fs_params[46];\n        vec4 param_13 = fa_mesh_fs_params[47];\n        vec4 param_14 = fa_mesh_fs_params[48];\n        vec4 param_15 = fa_mesh_fs_params[49];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3844 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3844 * fa_mesh_fs_params[45].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4490;\n        if (L.aniso >= 0.0)\n        {\n            _4490 = L.b;\n        }\n        else\n        {\n            _4490 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4490, v), _4490), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4523 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4523.x) + (vec3(L.f90) * _4523.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4578 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4578.x) + _4578.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4055 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4055.x) + vec3(_4055.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4607 = clamp(s.metallic, 0.0, 1.0);\n    float _4611 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4618 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4607));\n    vec3 f0 = _4618;\n    vec3 _4622 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4622;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4607;\n    float param_5 = _4611;\n    vec3 param_6 = _4618;\n    FaLayers _4639 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4639.on)\n    {\n        FaLayers param_7 = _4639;\n        vec3 param_8 = _4622;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4611;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _4622;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _4611;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4934;\n    if (fa_lm.z > 0.5)\n    {\n        _4934 = 0.0;\n    }\n    else\n    {\n        _4934 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4945 = _4934 < 1.0;\n    bool _4951;\n    if (_4945)\n    {\n        int param = li;\n        _4951 = fa_light_baked(param);\n    }\n    else\n    {\n        _4951 = _4945;\n    }\n    return _4951 ? _4934 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _660 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _673 = (c - (ru * hx)) - p;\n        vec3 _679 = ru * (2.0 * hx);\n        float _685 = max(dot(_679, _679), 9.9999999392252902907785028219223e-09);\n        float _689 = dot(_673, _679);\n        float t = clamp((-_689) / _685, 0.0, 1.0);\n        if (_660)\n        {\n            float _704 = dot(r, _679);\n            float _710 = _685 - (_704 * _704);\n            if (abs(_710) > (9.9999997473787516355514526367188e-06 * _685))\n            {\n                t = clamp(((dot(r, _673) * _704) - _689) / _710, 0.0, 1.0);\n            }\n        }\n        return (p + _673) + (_679 * t);\n    }\n    vec3 q = p;\n    float _742 = dot(r, axis);\n    bool _750;\n    if (_660)\n    {\n        _750 = abs(_742) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _750 = _660;\n    }\n    if (_750)\n    {\n        float _760 = dot(c - p, axis) / _742;\n        if (_760 > 0.0)\n        {\n            q = p + (r * _760);\n        }\n    }\n    vec3 _773 = q - c;\n    vec2 xy = vec2(dot(_773, ru), dot(_773, uu));\n    if (shape > 0.5)\n    {\n        float _788 = length(xy);\n        if (_788 > hx)\n        {\n            xy *= (hx / _788);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _430 = abs(d);\n    float _432 = _430.x;\n    float _434 = _430.y;\n    bool _435 = _432 >= _434;\n    bool _443;\n    if (_435)\n    {\n        _443 = _432 >= _430.z;\n    }\n    else\n    {\n        _443 = _435;\n    }\n    int _444;\n    if (_443)\n    {\n        _444 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _459;\n        if (_434 >= _430.z)\n        {\n            _459 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _459 = (d.z > 0.0) ? 4 : 5;\n        }\n        _444 = _459;\n    }\n    return _444;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _580 = dot(d, right);\n    float _584 = dot(d, up);\n    float _595;\n    if (((_580 * _580) + (_584 * _584)) > 1.0000000133514319600180897396058e-10)\n    {\n        _595 = atan(_584, _580) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _595 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_595 - floor(_595)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _826 = fa_light_base(param);\n    bool _830 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _826;\n    vec4 _834 = fa_light_texel(param_1);\n    int param_2 = _826 + 1;\n    vec4 _839 = fa_light_texel(param_2);\n    float _842 = _839.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _854 = _830 && (_842 > 2.5);\n    fa_light_is_area = _854;\n    bool _856 = _842 < 0.5;\n    vec3 l;\n    if (_856)\n    {\n        l = normalize(_834.xyz);\n        if (_830)\n        {\n            int param_3 = _826 + 6;\n            vec4 _870 = fa_light_texel(param_3);\n            if (_870.z > 0.5)\n            {\n                int param_4 = _826 + 4;\n                vec4 _880 = fa_light_texel(param_4);\n                int param_5 = _826 + 5;\n                vec4 _885 = fa_light_texel(param_5);\n                vec2 param_6 = _870.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _880.xyz) * _880.w, (-dot(world_pos, _885.xyz)) * _885.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _915 = _834.xyz;\n        vec3 _917 = _915 - world_pos;\n        vec3 to_light = _917;\n        float _920 = length(_917);\n        float reach = _920;\n        bool front = true;\n        if (_854)\n        {\n            int param_8 = _826 + 7;\n            reach = max(_920 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _826 + 4;\n            vec4 _944 = fa_light_texel(param_9);\n            int param_10 = _826 + 5;\n            vec4 _949 = fa_light_texel(param_10);\n            int param_11 = _826 + 6;\n            vec4 _954 = fa_light_texel(param_11);\n            float _955 = _954.w;\n            int param_12 = _826 + 2;\n            vec3 _962 = normalize(fa_light_texel(param_12).xyz);\n            bool _964 = _955 > 1.5;\n            bool _972;\n            if (!_964)\n            {\n                _972 = dot(_962, to_light) < 0.0;\n            }\n            else\n            {\n                _972 = _964;\n            }\n            front = _972;\n            vec3 r = vec3(0.0);\n            vec3 _981 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _985 = dot(n, n) > 0.5;\n            bool _993;\n            if (_985)\n            {\n                _993 = dot(_981, _981) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _993 = _985;\n            }\n            if (_993)\n            {\n                r = reflect(-normalize(_981), normalize(n));\n            }\n            vec3 param_13 = _915;\n            vec3 param_14 = _962;\n            vec3 param_15 = _944.xyz;\n            vec3 param_16 = _949.xyz;\n            float param_17 = _944.w;\n            float param_18 = _949.w;\n            float param_19 = _955;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1029 = length(to_light);\n        dist = _1029;\n        l = to_light / vec3(max(_1029, 9.9999997473787516355514526367188e-05));\n        float _1043 = reach / max(_834.w, 0.001000000047497451305389404296875);\n        float _1049 = clamp(1.0 - (_1043 * _1043), 0.0, 1.0);\n        float _1051;\n        if (front)\n        {\n            _1051 = _1049 * _1049;\n        }\n        else\n        {\n            _1051 = 0.0;\n        }\n        atten = _1051;\n        bool _1062 = _842 < 2.5;\n        if ((_842 > 1.5) && _1062)\n        {\n            int param_22 = _826 + 2;\n            vec4 _1070 = fa_light_texel(param_22);\n            float _1080 = _1070.w;\n            int param_23 = _826 + 3;\n            vec4 _1085 = fa_light_texel(param_23);\n            float _1086 = _1085.x;\n            float cos_inner = _1086;\n            if (_1086 > 1.5)\n            {\n                cos_inner = mix(_1080, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1080, cos_inner, dot(-l, normalize(_1070.xyz)));\n        }\n        if (_830 && (_842 < 1.5))\n        {\n            int param_24 = _826 + 6;\n            vec4 _1110 = fa_light_texel(param_24);\n            if (_1110.z > 0.5)\n            {\n                vec3 _1118 = -to_light;\n                int param_25 = _826 + 4;\n                int param_26 = _826 + 5;\n                vec3 _1132 = fa_light_texel(param_25).xyz;\n                vec3 _1136 = fa_light_texel(param_26).xyz;\n                vec3 _1145 = vec3(dot(_1118, _1132), dot(_1118, _1136), dot(_1118, cross(_1132, _1136)));\n                vec3 param_27 = _1145;\n                int _1149 = fa_cube_face(param_27);\n                int param_28 = _1149;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1176 = vec2(dot(_1145, cross(param_29, param_30)), dot(_1145, param_30)) / vec2(max(dot(_1145, param_29), 9.9999997473787516355514526367188e-05));\n                int _1180 = _1149 / 3;\n                vec2 param_31 = _1110.xy + (vec2(float(_1149 - (_1180 * 3)), float(_1180)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1176.x), 0.5 - (0.5 * _1176.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _826 + 7;\n            vec4 _1210 = fa_light_texel(param_33);\n            if (_1210.z > 0.5)\n            {\n                int param_34 = _826 + 2;\n                int param_35 = _826 + 4;\n                int param_36 = _826 + 5;\n                vec2 param_37 = _1210.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_830 && _1062)\n            {\n                int param_42 = _826 + 6;\n                vec4 _1257 = fa_light_texel(param_42);\n                int param_43 = _826 + 7;\n                vec4 _1262 = fa_light_texel(param_43);\n                bool _1265 = _1257.z > 0.5;\n                bool _1272;\n                if (!_1265)\n                {\n                    _1272 = _1262.z > 0.5;\n                }\n                else\n                {\n                    _1272 = _1265;\n                }\n                if (_1272)\n                {\n                    int param_44 = _826 + 2;\n                    vec4 _1279 = fa_light_texel(param_44);\n                    vec3 _1283 = normalize(_1279.xyz);\n                    int param_45 = _826 + 4;\n                    vec4 _1288 = fa_light_texel(param_45);\n                    int param_46 = _826 + 5;\n                    vec4 _1293 = fa_light_texel(param_46);\n                    if (_1265)\n                    {\n                        vec3 _1301 = -to_light;\n                        float _1308 = _1279.w;\n                        float _1324 = 0.5 / max(dot(_1301, _1283) * (sqrt(max(1.0 - (_1308 * _1308), 0.0)) / max(_1308, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1257.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1301, _1288.xyz) * _1324), 0.5 - (dot(_1301, _1293.xyz) * _1324));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1262.z > 0.5)\n                    {\n                        vec2 param_49 = _1262.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1283;\n                        vec3 param_52 = _1288.xyz;\n                        vec3 param_53 = _1293.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6061 = _839.xyz * atten;\n    if (_830)\n    {\n        _6061 *= fa_light_tint;\n    }\n    int _1392;\n    if (_856)\n    {\n        _1392 = 0;\n    }\n    else\n    {\n        _1392 = ((_842 > 1.5) && (_842 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6061, atten, 1.0, dist, _1392);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2129;\n    if (i == 0)\n    {\n        _2129 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2145;\n        if (i == 1)\n        {\n            _2145 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2153;\n            if (i == 2)\n            {\n                _2153 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2153 = fa_shadows[24].w;\n            }\n            _2145 = _2153;\n        }\n        _2129 = _2145;\n    }\n    return _2129;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2186 = fa_shadow_depth(param, param_1);\n    float _2190;\n    if (conv.x < 0.5)\n    {\n        _2190 = _2186;\n    }\n    else\n    {\n        _2190 = (conv.y * conv.z) / (conv.z - (_2186 * (conv.z - conv.y)));\n    }\n    return _2190;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2117 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2117), sin(_2117)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2236 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2245;\n        if (k < 0.0)\n        {\n            _2245 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        float _2265 = clamp((_2245 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2236;\n            vec2 _2284 = fa_shadow_vogel(param_3, param_4, param_5) * _2265;\n            vec2 param_6 = uv + (_2284 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2296 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2296 < (zr - (length(_2284) * plane)))\n            {\n                sum += _2296;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2322 = sum / cnt;\n        float _2332;\n        if (k < 0.0)\n        {\n            _2332 = (-k) / max(_2322, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2332 = k;\n        }\n        radius = clamp(((max(zr - _2322, 0.0) * unit) * _2332) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2354 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2354; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2354;\n        float param_11 = _2236;\n        vec2 _2373 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2373 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2373) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2354);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2415 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2420 = clamp(dot(n, l), 0.0, 1.0);\n    float _2426 = sqrt(1.0 - (_2420 * _2420));\n    float _2433 = min(_2426 / max(_2420, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2426)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2415);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2415;\n    float param_5 = _2415 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2415;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2893)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2975 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2975;\n        if (_2975 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3000;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3000 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3000 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3019 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3000, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3030 = clamp((_2908 - (fa_shadow_split_at(param_7) - _3019)) / _3019, 0.0, 1.0);\n        if (_3030 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2893)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3051 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3051;\n                if (_3051 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3030);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4678 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4685;\n    if (!_4678)\n    {\n        _4685 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4685 = _4678;\n    }\n    if (_4685)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4698 = fa_light_texel(param);\n    float _4699 = _4698.y;\n    float len = _4699;\n    if (_4699 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4711 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4721 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4711);\n    if (_4721 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4727 = len;\n    float _4730 = min(_4727, 0.89999997615814208984375 * dist);\n    len = _4730;\n    float _4735 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4711);\n    float _4740 = _4735 + (0.5 * _4730);\n    vec3 _4746 = world + (gn * _4735);\n    float _4748 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4812;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4763 = (float(k) + _4748) * 0.083333335816860198974609375;\n        vec3 _4771 = _4746 + (l * (_4763 * len));\n        vec4 _4777 = vec4(_4771, 1.0);\n        float _4783 = dot(fa_mesh_fs_params[28], _4777);\n        if (_4783 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4803 = vec2(dot(fa_mesh_fs_params[26], _4777), dot(fa_mesh_fs_params[27], _4777)) / vec2(_4783);\n        float _4807 = _4803.x * 0.5;\n        float _4808 = _4807 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4812 = (_4803.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4812 = 0.5 - (_4803.y * 0.5);\n        }\n        bool _4828 = _4808 < 0.0;\n        bool _4835;\n        if (!_4828)\n        {\n            _4835 = _4808 >= 1.0;\n        }\n        else\n        {\n            _4835 = _4828;\n        }\n        bool _4842;\n        if (!_4835)\n        {\n            _4842 = _4812 < 0.0;\n        }\n        else\n        {\n            _4842 = _4835;\n        }\n        bool _4849;\n        if (!_4842)\n        {\n            _4849 = _4812 >= 1.0;\n        }\n        else\n        {\n            _4849 = _4842;\n        }\n        if (_4849)\n        {\n            break;\n        }\n        vec4 _4868 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4808, _4812) * fa_mesh_fs_params[24].zw), 0);\n        if (_4868.w < 0.5)\n        {\n            continue;\n        }\n        float _4887 = (dot(fa_mesh_fs_params[29].xyz, _4771) + fa_mesh_fs_params[29].w) - _4868.x;\n        if ((_4887 > _4735) && (_4887 < _4740))\n        {\n            occ = max(occ, (1.0 - (_4763 * _4763)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4808, 0.5 - _4807), min(_4812, 1.0 - _4812))));\n        }\n    }\n    return 1.0 - (occ * _4721);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4990 = fa_baked_keep(param);\n    if (_4990 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5016 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6194 = _5016.color;\n    float _6195 = _5016.attenuation;\n    float _6196 = _5016.shadow;\n    bool _5019 = _5016.type == 0;\n    if (_5019 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5016.direction;\n        float _5030 = fa_shadow_factor(param_5, param_6);\n        _6196 = _5030;\n        _6194 *= _5030;\n    }\n    else\n    {\n        bool _5041 = _5016.type != 0;\n        bool _5047;\n        if (_5041)\n        {\n            _5047 = _6195 > 0.0;\n        }\n        else\n        {\n            _5047 = _5041;\n        }\n        if (_5047)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5016.direction;\n            float _5066 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6196 = _5066;\n            _6194 *= _5066;\n        }\n    }\n    bool _5076 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5082;\n    if (_5076)\n    {\n        _5082 = _6195 > 0.0;\n    }\n    else\n    {\n        _5082 = _5076;\n    }\n    if (_5082)\n    {\n        float _5089;\n        if (_5019)\n        {\n            _5089 = 1000000000.0;\n        }\n        else\n        {\n            _5089 = _5016._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5016.direction;\n        float param_18 = _5089;\n        float _5107 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6196 *= _5107;\n        _6194 *= _5107;\n    }\n    float _5120 = _6195;\n    float _5121 = _5120 * _4990;\n    _6195 = _5121;\n    vec3 _5125 = _6194;\n    vec3 _5126 = _5125 * _4990;\n    _6194 = _5126;\n    return LightSample(_5016.direction, _5126, _5121, _6196, _5016._distance, _5016.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3075 = int(fa_shadows[25].x + 0.5);\n    float _3085 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3090 = _3075 > 0;\n    bool _3099;\n    if (_3090)\n    {\n        int param = _3075 - 1;\n        _3099 = _3085 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3099 = _3090;\n    }\n    if (_3099)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3105 = _3075 > 1;\n        bool _3112;\n        if (_3105)\n        {\n            _3112 = _3085 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3112 = _3105;\n        }\n        if (_3112)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3118 = _3075 > 2;\n        bool _3125;\n        if (_3118)\n        {\n            _3125 = _3085 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3125 = _3118;\n        }\n        if (_3125)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3131 = _3075 > 3;\n        bool _3138;\n        if (_3131)\n        {\n            _3138 = _3085 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3138 = _3131;\n        }\n        if (_3138)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5903 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5903 = -_5903;\n    }\n    vec3 _5543 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n    Surface _5551 = fa_standard_surface(param_1);\n    vec3 _5942 = _5551.albedo;\n    float _5943 = _5551.alpha;\n    vec3 _5944 = _5551.normal;\n    float _5945 = _5551.metallic;\n    float _5946 = _5551.roughness;\n    float _5947 = _5551.occlusion;\n    vec3 _5948 = _5551.emission;\n    float _5949 = _5551.clearcoat;\n    float _5950 = _5551.clearcoat_roughness;\n    vec3 _5951 = _5551.sheen_color;\n    float _5952 = _5551.sheen_roughness;\n    float _5953 = _5551.anisotropy;\n    float _5954 = _5551.anisotropy_rotation;\n    float _5955 = _5551.specular;\n    float _5956 = _5551.ior;\n    vec3 _5957 = _5551.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n    Surface param_3 = _5551;\n    surface(param_2, param_3);\n    _5942 = param_3.albedo;\n    _5943 = param_3.alpha;\n    _5944 = param_3.normal;\n    _5945 = param_3.metallic;\n    _5946 = param_3.roughness;\n    _5947 = param_3.occlusion;\n    _5948 = param_3.emission;\n    _5949 = param_3.clearcoat;\n    _5950 = param_3.clearcoat_roughness;\n    _5951 = param_3.sheen_color;\n    _5952 = param_3.sheen_roughness;\n    _5953 = param_3.anisotropy;\n    _5954 = param_3.anisotropy_rotation;\n    _5955 = param_3.specular;\n    _5956 = param_3.ior;\n    _5957 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5903;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5942 = param_6;\n    _5944 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5942;\n    }\n    else\n    {\n        vec3 _5589 = _5944;\n        vec3 _5590 = normalize(_5589);\n        _5944 = _5590;\n        vec3 param_8 = _5590;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n        Surface param_10 = Surface(_5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5609 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5609; ln++)\n        {\n            int param_12 = ln;\n            int _5622 = fa_cl_light(param_12);\n            int param_13 = _5622;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5622;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5903;\n            LightSample _5638 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5903, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n            Surface param_18 = Surface(_5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957);\n            LightSample param_19 = _5638;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5653 = result;\n    vec3 _5654 = _5653 + _5948;\n    result = _5654;\n    vec3 param_20 = _5654;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5663 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5670;\n    if (!_5663)\n    {\n        _5670 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5670 = _5663;\n    }\n    if (_5670)\n    {\n        vec3 _5679 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5685 = dot(_5679, fa_mesh_fs_params[9].xyz);\n        bool _5689 = fa_mesh_fs_params[9].w > 0.5;\n        float _5690;\n        if (_5689)\n        {\n            _5690 = _5685;\n        }\n        else\n        {\n            _5690 = length(_5679);\n        }\n        float _5702 = _5690 - fa_mesh_fs_params[8].x;\n        if (_5702 > 0.0)\n        {\n            float _5711 = fa_mesh_fs_params[7].w * _5702;\n            float tau = _5711 * _5711;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5727;\n                if (_5689)\n                {\n                    _5727 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5685);\n                }\n                else\n                {\n                    _5727 = fa_mesh_fs_params[0].y;\n                }\n                float _5748 = mix(_5727, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5690, 0.0, 1.0));\n                float _5752 = fa_world_pos.y - _5748;\n                float _5757 = _5748 - fa_mesh_fs_params[8].z;\n                float _5762 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5765 = _5757 <= 0.0;\n                bool _5766 = !_5765;\n                bool _5772;\n                if (_5766)\n                {\n                    _5772 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5772 = _5765;\n                }\n                float _5773;\n                if (_5772)\n                {\n                    _5773 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5773 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5757, 80.0));\n                }\n                bool _5800;\n                if (_5766)\n                {\n                    _5800 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5800 = _5765;\n                }\n                float _5801;\n                if (_5800)\n                {\n                    _5801 = fa_mesh_fs_params[8].y * _5757;\n                }\n                else\n                {\n                    _5801 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5757, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5826 = _5762 <= 0.0;\n                bool _5833;\n                if (!_5826)\n                {\n                    _5833 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5833 = _5826;\n                }\n                float _5834;\n                if (_5833)\n                {\n                    _5834 = fa_mesh_fs_params[8].y * _5762;\n                }\n                else\n                {\n                    _5834 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5762, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5861;\n                if (abs(_5752) < 0.001000000047497451305389404296875)\n                {\n                    _5861 = _5773;\n                }\n                else\n                {\n                    _5861 = (_5834 - _5801) / _5752;\n                }\n                tau += (_5702 * max(_5861, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5943);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_482",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2139",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
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
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    vec4 _243 = (_785 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _748, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    vec4 _243 = (_785 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _748, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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

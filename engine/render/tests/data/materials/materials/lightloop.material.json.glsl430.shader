{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "ae26515a48b1a8d2e7a58b8583b7398bc5ad5b1e5314aaacf65f28e91c149fe7",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3885[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1397 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1436 = vec4(world_pos, 1.0);\n    float _1442 = dot(fa_mesh_fs_params[16], _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1464 = vec2(dot(fa_mesh_fs_params[14], _1436), dot(fa_mesh_fs_params[15], _1436)) / vec2(_1442);\n    int _1468 = int(fa_mesh_fs_params[18].x);\n    int _1472 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1548 = fa_cluster_texel(param);\n    return ivec2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4719 = fa_cluster_lookup(param);\n    fa_cl_slot = _4719.x;\n    fa_cl_local = _4719.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5096 = fa_linear_to_srgb(param);\n        c = _5096;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5104 = fa_srgb_to_linear(param_1);\n            c = _5104;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    vec3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    vec3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    vec3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5135 = fa_tex_fix(param_2, param_3);\n    vec4 _6274 = base_t;\n    _6274.x = _5135.x;\n    _6274.y = _5135.y;\n    _6274.z = _5135.z;\n    base_t = _6274;\n    vec4 _5149 = (_6274 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6080 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5181 = fa_tex_fix(param_6, param_7);\n        vec3 _5184 = (_5181 * 2.0) - vec3(1.0);\n        vec2 _5189 = _5184.xy * fa_mesh_fs_params[6].x;\n        vec3 _6282 = _5184;\n        _6282.x = _5189.x;\n        _6282.y = _5189.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6282;\n        _6080 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5217 = fa_tex_fix(param_12, param_13);\n    vec4 _6285 = mrt;\n    _6285.x = _5217.x;\n    _6285.y = _5217.y;\n    _6285.z = _5217.z;\n    mrt = _6285;\n    vec4 _5245 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5245.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5256 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5286 = fa_tex_fix(param_20, param_21);\n    float _6085 = fa_mesh_fs_params[20].x;\n    float _6086 = fa_mesh_fs_params[20].y;\n    float _6089 = fa_mesh_fs_params[20].z;\n    float _6088 = fa_mesh_fs_params[21].w;\n    float _6091 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6085 *= _5256.y;\n            _6086 *= _5256.z;\n            _6088 *= _5245.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6089 *= mrt.x;\n            _6091 *= mrt.w;\n        }\n    }\n    return Surface(_5149.xyz, _5149.w, _6080, clamp(fa_mesh_fs_params[5].x * _5217.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5217.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5256.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5286), _6085, _6086, fa_mesh_fs_params[21].xyz, _6088, _6089, fa_mesh_fs_params[20].w, _6091, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1628 = rect.zw - rect.xy;\n    vec2 _1632 = _1628 * atlas;\n    vec2 _1636 = ddx * _1632;\n    vec2 _1640 = ddy * _1632;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1628), clamp(0.5 * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1673 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    vec3 _1686 = dFdx(world_pos);\n    vec3 _1689 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1707;\n    vec4 _1711 = fa_light_texel(param_1);\n    vec2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    vec4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1734 = int(_1693.z);\n    vec3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        vec4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        vec4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        vec4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        vec4 _1794 = fa_light_texel(param_7);\n        vec3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        vec3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        vec3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0, 1.0);\n        if (_1852 <= 0.0)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5 - abs(_1816)) * 10.0, 0.0, 1.0) * _1852) * _1769.x;\n        vec2 _1880 = vec2(_1802 + 0.5, 0.5 - _1809);\n        vec2 _1890 = vec2(dot(_1797, _1686), dot(_1804, _1686));\n        vec2 _1900 = vec2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        vec4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        vec4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        vec4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            vec4 param_11 = _1910;\n            vec2 param_12 = _1880;\n            vec2 param_13 = _1714;\n            vec2 param_14 = _1890;\n            vec2 param_15 = _1900;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5) && (_1724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1951 = fa_dc_to_linear(param_16);\n                vec4 _6168 = tx;\n                _6168.x = _1951.x;\n                _6168.y = _1951.y;\n                _6168.z = _1951.z;\n                tx = _6168;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1872 * tex_a) * _1905.w, 0.0, 1.0)));\n        if (_1915.z > _1915.x)\n        {\n            vec4 param_17 = _1915;\n            vec2 param_18 = _1880;\n            vec2 param_19 = _1714;\n            vec2 param_20 = _1890;\n            vec2 param_21 = _1900;\n            vec4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5)\n            {\n                vec3 param_22 = _1995.xyz;\n                vec3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            vec3 _2014 = (_1999 * 2.0) - vec3(1.0);\n            vec2 _2019 = _2014.xy * _1769.y;\n            vec3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            vec3 _2044 = normalize(normal);\n            normal = normalize(mix(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125)) + (_2041 - (_2044 * dot(_2044, _2041)))), vec3(clamp(_1872 * (_1925 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4689;\n    if (fa_lm.z > 0.5)\n    {\n        _4689 = 0.0;\n    }\n    else\n    {\n        _4689 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4700 = _4689 < 1.0;\n    bool _4706;\n    if (_4700)\n    {\n        int param = li;\n        _4706 = fa_light_baked(param);\n    }\n    else\n    {\n        _4706 = _4700;\n    }\n    return _4706 ? _4689 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _646 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _659 = (c - (ru * hx)) - p;\n        vec3 _665 = ru * (2.0 * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0, 1.0);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06 * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0, 1.0);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    vec3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0)\n        {\n            q = p + (r * _746);\n        }\n    }\n    vec3 _759 = q - c;\n    vec2 xy = vec2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10)\n    {\n        _581 = atan(_570, _566) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _581 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_581 - floor(_581)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _812;\n    vec4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    vec4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _840 = _816 && (_828 > 2.5);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5;\n    vec3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            vec4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5)\n            {\n                int param_4 = _812 + 4;\n                vec4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                vec4 _871 = fa_light_texel(param_5);\n                vec2 param_6 = _856.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _901 = _820.xyz;\n        vec3 _903 = _901 - world_pos;\n        vec3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _812 + 4;\n            vec4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            vec4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            vec4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            vec3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            vec3 r = vec3(0.0);\n            vec3 _967 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            vec3 param_13 = _901;\n            vec3 param_14 = _948;\n            vec3 param_15 = _930.xyz;\n            vec3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / vec3(max(_1015, 9.9999997473787516355514526367188e-05));\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875);\n        float _1035 = clamp(1.0 - (_1029 * _1029), 0.0, 1.0);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5;\n        if ((_828 > 1.5) && _1048)\n        {\n            int param_22 = _812 + 2;\n            vec4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            vec4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5)\n            {\n                cos_inner = mix(_1066, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5))\n        {\n            int param_24 = _812 + 6;\n            vec4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5)\n            {\n                vec3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                vec3 _1118 = fa_light_texel(param_25).xyz;\n                vec3 _1122 = fa_light_texel(param_26).xyz;\n                vec3 _1131 = vec3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                vec3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1162 = vec2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / vec2(max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05));\n                int _1166 = _1135 / 3;\n                vec2 param_31 = _1096.xy + (vec2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1162.x), 0.5 - (0.5 * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            vec4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                vec2 param_37 = _1196.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                vec4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                vec4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    vec4 _1265 = fa_light_texel(param_44);\n                    vec3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    vec4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    vec4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        vec3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5 / max(dot(_1287, _1269) * (sqrt(max(1.0 - (_1294 * _1294), 0.0)) / max(_1294, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1243.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1287, _1274.xyz) * _1310), 0.5 - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5)\n                    {\n                        vec2 param_49 = _1248.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1269;\n                        vec3 param_52 = _1274.xyz;\n                        vec3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5886 = _825.xyz * atten;\n    if (_816)\n    {\n        _5886 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5) && (_828 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5886, atten, 1.0, dist, _1379);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4918 = n < 0;\n    bool _4925;\n    if (!_4918)\n    {\n        _4925 = n >= fa_light_count();\n    }\n    else\n    {\n        _4925 = _4918;\n    }\n    if (_4925)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4933 = fa_cl_light(param);\n    int param_1 = _4933;\n    float _4937 = fa_baked_keep(param_1);\n    if (_4937 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4933;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4953 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4953.direction, _4953.color * _4937, _4953.attenuation * _4937, _4953.shadow, _4953._distance, _4953.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2224 = vec2(cos(_2218), sin(_2218));\n    vec2 dir = _2224;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5) * 0.0625) * _2252;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2271));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0) * unit) * _2323) / texel_m, 1.5, 16.0);\n        dir = _2224;\n    }\n    float lit = 0.0;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5) / float(_2349)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2368));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2135 = fa_shadows[24].w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2414 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2419 = clamp(dot(n, l), 0.0, 1.0);\n    float _2425 = sqrt(1.0 - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2425)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2414);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2414;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2893)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2975 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2975;\n        if (_2975 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3000;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3000 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3000 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3019 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3000, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3030 = clamp((_2908 - (fa_shadow_split_at(param_7) - _3019)) / _3019, 0.0, 1.0);\n        if (_3030 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2893)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3051 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3051;\n                if (_3051 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3030);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4425 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4432;\n    if (!_4425)\n    {\n        _4432 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4432 = _4425;\n    }\n    if (_4432)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4445 = fa_light_texel(param);\n    float _4446 = _4445.y;\n    float len = _4446;\n    if (_4446 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4458 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4468 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4458);\n    if (_4468 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4474 = len;\n    float _4477 = min(_4474, 0.89999997615814208984375 * dist);\n    len = _4477;\n    float _4482 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4458);\n    float _4487 = _4482 + (0.5 * _4477);\n    vec3 _4493 = world + (gn * _4482);\n    float _4495 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4559;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4510 = (float(k) + _4495) * 0.083333335816860198974609375;\n        vec3 _4518 = _4493 + (l * (_4510 * len));\n        vec4 _4524 = vec4(_4518, 1.0);\n        float _4530 = dot(fa_mesh_fs_params[28], _4524);\n        if (_4530 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4550 = vec2(dot(fa_mesh_fs_params[26], _4524), dot(fa_mesh_fs_params[27], _4524)) / vec2(_4530);\n        float _4554 = _4550.x * 0.5;\n        float _4555 = _4554 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4559 = (_4550.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4559 = 0.5 - (_4550.y * 0.5);\n        }\n        bool _4575 = _4555 < 0.0;\n        bool _4582;\n        if (!_4575)\n        {\n            _4582 = _4555 >= 1.0;\n        }\n        else\n        {\n            _4582 = _4575;\n        }\n        bool _4589;\n        if (!_4582)\n        {\n            _4589 = _4559 < 0.0;\n        }\n        else\n        {\n            _4589 = _4582;\n        }\n        bool _4596;\n        if (!_4589)\n        {\n            _4596 = _4559 >= 1.0;\n        }\n        else\n        {\n            _4596 = _4589;\n        }\n        if (_4596)\n        {\n            break;\n        }\n        vec4 _4623 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4555, _4559) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4623.w < 0.5)\n        {\n            continue;\n        }\n        float _4642 = (dot(fa_mesh_fs_params[29].xyz, _4518) + fa_mesh_fs_params[29].w) - _4623.x;\n        if ((_4642 > _4482) && (_4642 < _4487))\n        {\n            occ = max(occ, (1.0 - (_4510 * _4510)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4555, 0.5 - _4554), min(_4559, 1.0 - _4559))));\n        }\n    }\n    return 1.0 - (occ * _4468);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4745 = fa_baked_keep(param);\n    if (_4745 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4771 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6032 = _4771.color;\n    float _6033 = _4771.attenuation;\n    float _6034 = _4771.shadow;\n    bool _4774 = _4771.type == 0;\n    if (_4774 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4771.direction;\n        float _4785 = fa_shadow_factor(param_5, param_6);\n        _6034 = _4785;\n        _6032 *= _4785;\n    }\n    else\n    {\n        bool _4796 = _4771.type != 0;\n        bool _4802;\n        if (_4796)\n        {\n            _4802 = _6033 > 0.0;\n        }\n        else\n        {\n            _4802 = _4796;\n        }\n        if (_4802)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4771.direction;\n            float _4821 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6034 = _4821;\n            _6032 *= _4821;\n        }\n    }\n    bool _4831 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4837;\n    if (_4831)\n    {\n        _4837 = _6033 > 0.0;\n    }\n    else\n    {\n        _4837 = _4831;\n    }\n    if (_4837)\n    {\n        float _4844;\n        if (_4774)\n        {\n            _4844 = 1000000000.0;\n        }\n        else\n        {\n            _4844 = _4771._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4771.direction;\n        float param_18 = _4844;\n        float _4862 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6034 *= _4862;\n        _6032 *= _4862;\n    }\n    float _4875 = _6033;\n    float _4876 = _4875 * _4745;\n    _6033 = _4876;\n    vec3 _4880 = _6032;\n    vec3 _4881 = _4880 * _4745;\n    _6032 = _4881;\n    return LightSample(_4771.direction, _4881, _4876, _6034, _4771._distance, _4771.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4892 = n < 0;\n    bool _4899;\n    if (!_4892)\n    {\n        _4899 = n >= fa_light_count();\n    }\n    else\n    {\n        _4899 = _4892;\n    }\n    if (_4899)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4914 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4914;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3810 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3818 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3821 = int(_3810);\n    int _3824 = int(_3818);\n    float _3834 = _3818 - float(_3824);\n    int _3890 = (_3821 * 9) + _3824;\n    int _3910 = ((_3821 + 1) * 9) + _3824;\n    return mix(mix(_3885[_3890], _3885[_3890 + 1], _3834), mix(_3885[_3910], _3885[_3910 + 1], _3834), _3810 - float(_3821));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5898 = false;\n    float _5899 = 1.0;\n    float _5900 = 1.0;\n    float _5901 = 1.0;\n    float _5902 = 0.0;\n    float _5903 = 0.0;\n    float _5904 = 0.0;\n    float _5905 = 0.0;\n    float _5907 = 1.0;\n    bool _5908 = false;\n    vec3 _5909 = vec3(0.0);\n    float _5910 = 1.0;\n    float _5911 = 1.0;\n    float _5912 = 1.0;\n    float _5913 = 0.0;\n    float _5914 = 0.0;\n    vec3 _5915 = vec3(1.0, 0.0, 0.0);\n    vec3 _5916 = vec3(0.0, 0.0, 1.0);\n    float _5917 = 1.0;\n    float _5918 = 1.0;\n    float _3961 = clamp(s.specular, 0.0, 1.0);\n    float _3965 = clamp(s.ior, 1.0, 3.0);\n    bool _3970 = (_3961 != 1.0) || (_3965 != 1.5);\n    bool _3979;\n    if (!_3970)\n    {\n        _3979 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3979 = _3970;\n    }\n    if (_3979)\n    {\n        float _3987 = (_3965 - 1.0) / (_3965 + 1.0);\n        f0 = mix(min(vec3(_3987 * _3987) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3961, s.albedo, vec3(metallic));\n        _5899 = mix(_3961, 1.0, metallic);\n        _5898 = true;\n    }\n    float _4014 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4014 > 0.0)\n    {\n        float _4022 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5902 = _4014;\n        _5903 = _4022;\n        float _4029 = _4022 * _4022;\n        _5904 = _4029;\n        _5905 = _4029 * _4029;\n        float _4041 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5907 = _4041;\n        _5900 = 1.0 - (_4014 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4041, 0.0, 1.0), 5.0))));\n        _5898 = true;\n    }\n    vec3 _4060 = max(s.sheen_color, vec3(0.0));\n    float _4069 = max(_4060.x, max(_4060.y, _4060.z));\n    if (_4069 > 0.0)\n    {\n        float _4077 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5908 = true;\n        _5909 = _4060;\n        _5910 = _4077;\n        _5911 = _4077 * _4077;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4077;\n        float _4094 = fa_sheen_albedo(param, param_1);\n        _5913 = _4094;\n        _5912 = 1.0 - min(_4069 * _4094, 1.0);\n        _5898 = true;\n    }\n    _5901 = _5900 * _5912;\n    float _4113 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4113 != 0.0)\n    {\n        vec3 _4128 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4128;\n        if (dot(_4128, _4128) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4140 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4140.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4140.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4140.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4144 = t;\n        vec3 _4145 = normalize(_4144);\n        t = _4145;\n        vec3 _4170 = normalize((_4145 * cos(s.anisotropy_rotation)) + ((cross(n, _4145) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5915 = _4170;\n        _5916 = cross(n, _4170);\n        float _4180 = roughness * roughness;\n        float _4186 = mix(_4180, 1.0, _4113 * _4113);\n        bool _4188 = _4113 > 0.0;\n        _5917 = _4188 ? _4186 : _4180;\n        _5918 = _4188 ? _4180 : _4186;\n        _5914 = _4113;\n        _5898 = true;\n    }\n    return FaLayers(_5898, _5899, _5900, _5901, _5902, _5903, _5904, _5905, i.world_normal, _5907, _5908, _5909, _5910, _5911, _5912, _5913, _5914, _5915, _5916, _5917, _5918);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3742 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3745 = _3742.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3745 * _3745, exp2((-9.27999973297119140625) * ndv)) * _3745) + _3742.y)) + _3742.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3177 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3180 = _3177.x;\n    float _3182 = _3177.z;\n    vec2 e = vec2(_3180, _3182);\n    if (_3177.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3182)) * ((_3180 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3180)) * ((_3182 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3229;\n    if (lv == 0)\n    {\n        _3229 = 0.0;\n    }\n    else\n    {\n        _3229 = res + 2.0;\n    }\n    float _3239;\n    if (lv == 0)\n    {\n        _3239 = 0.0;\n    }\n    else\n    {\n        _3239 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3229, _3239)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3285;\n    if (res > 64.5)\n    {\n        _3285 = 5.0;\n    }\n    else\n    {\n        _3285 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3300 = clamp(rough, 0.0, 1.0) * (_3285 - 1.0);\n    int _3307 = int(min(floor(_3300), _3285 - 2.0));\n    float _3312 = _3300 - float(_3307);\n    vec3 param = d;\n    vec2 _3316 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3307;\n    vec2 param_4 = _3316;\n    vec3 _3326 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3312 < 0.00200000009499490261077880859375)\n    {\n        return _3326;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3307 + 1;\n    vec2 param_8 = _3316;\n    return mix(_3326, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3312));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3364 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3371 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3378 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3384 = dot(bx.xyz, d);\n    float _3388 = dot(by.xyz, d);\n    float _3392 = dot(bz.xyz, d);\n    float _3398;\n    if (_3384 > 9.9999999747524270787835121154785e-07)\n    {\n        _3398 = (1.0 - _3364) / _3384;\n    }\n    else\n    {\n        float _3412;\n        if (_3384 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3412 = ((-1.0) - _3364) / _3384;\n        }\n        else\n        {\n            _3412 = 1000000015047466219876688855040.0;\n        }\n        _3398 = _3412;\n    }\n    float tx = _3398;\n    float _3429;\n    if (_3388 > 9.9999999747524270787835121154785e-07)\n    {\n        _3429 = (1.0 - _3371) / _3388;\n    }\n    else\n    {\n        float _3442;\n        if (_3388 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3442 = ((-1.0) - _3371) / _3388;\n        }\n        else\n        {\n            _3442 = 1000000015047466219876688855040.0;\n        }\n        _3429 = _3442;\n    }\n    float ty = _3429;\n    float _3458;\n    if (_3392 > 9.9999999747524270787835121154785e-07)\n    {\n        _3458 = (1.0 - _3378) / _3392;\n    }\n    else\n    {\n        float _3471;\n        if (_3392 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3471 = ((-1.0) - _3378) / _3392;\n        }\n        else\n        {\n            _3471 = 1000000015047466219876688855040.0;\n        }\n        _3458 = _3471;\n    }\n    float _3483 = tx;\n    float _3486 = (_3483 > 0.0) ? _3483 : 1000000015047466219876688855040.0;\n    tx = _3486;\n    float _3487 = ty;\n    float _3490 = (_3487 > 0.0) ? _3487 : 1000000015047466219876688855040.0;\n    ty = _3490;\n    float _3500 = min(_3486, min(_3490, (_3458 > 0.0) ? _3458 : 1000000015047466219876688855040.0));\n    if (_3500 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3516 = (fa_world_pos + (d * _3500)) - posw.xyz;\n    vec3 _3521;\n    if (dot(_3516, _3516) > 1.0000000133514319600180897396058e-10)\n    {\n        _3521 = normalize(_3516);\n    }\n    else\n    {\n        _3521 = d;\n    }\n    return _3521;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3567 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3567 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3597 = rough * rough;\n            float _3628 = 0.60000002384185791015625 * _3597;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3597)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3628, 0.0500000007450580596923828125 + _3628, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3597 * 0.60000002384185791015625));\n        }\n        outc = base * _3567;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3687 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3687 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3719 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3719 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4221;\n        if (L.aniso >= 0.0)\n        {\n            _4221 = L.b;\n        }\n        else\n        {\n            _4221 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4221, v), _4221), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4257 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4257.x) + (vec3(L.f90) * _4257.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4315 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4315.x) + _4315.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3784 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3784.x) + vec3(_3784.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4354 = clamp(s.metallic, 0.0, 1.0);\n    float _4358 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4365 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4354));\n    vec3 f0 = _4365;\n    vec3 _4369 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4369;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4354;\n    float param_5 = _4358;\n    vec3 param_6 = _4365;\n    FaLayers _4386 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4386.on)\n    {\n        FaLayers param_7 = _4386;\n        vec3 param_8 = _4369;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4358;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4369;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4358;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4984 = fa_light_unshadowed(param, param_1);\n        float _4992 = dot(_4984.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4992 > bestPower)\n        {\n            bestPower = _4992;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5021 = fa_light(param_2, param_3);\n        float _5029;\n        if (dot(s.normal, _5021.direction) > 0.5)\n        {\n            _5029 = 1.0;\n        }\n        else\n        {\n            _5029 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5021.color) * _5029);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3075 = int(fa_shadows[25].x + 0.5);\n    float _3085 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3090 = _3075 > 0;\n    bool _3099;\n    if (_3090)\n    {\n        int param = _3075 - 1;\n        _3099 = _3085 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3099 = _3090;\n    }\n    if (_3099)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3105 = _3075 > 1;\n        bool _3112;\n        if (_3105)\n        {\n            _3112 = _3085 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3112 = _3105;\n        }\n        if (_3112)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3118 = _3075 > 2;\n        bool _3125;\n        if (_3118)\n        {\n            _3125 = _3085 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3125 = _3118;\n        }\n        if (_3125)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3131 = _3075 > 3;\n        bool _3138;\n        if (_3131)\n        {\n            _3138 = _3085 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3138 = _3131;\n        }\n        if (_3138)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5752 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5752 = -_5752;\n    }\n    vec3 _5422 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing);\n    Surface _5430 = fa_standard_surface(param_1);\n    vec3 _5783 = _5430.albedo;\n    float _5784 = _5430.alpha;\n    vec3 _5785 = _5430.normal;\n    float _5786 = _5430.metallic;\n    float _5787 = _5430.roughness;\n    float _5788 = _5430.occlusion;\n    vec3 _5789 = _5430.emission;\n    float _5790 = _5430.clearcoat;\n    float _5791 = _5430.clearcoat_roughness;\n    vec3 _5792 = _5430.sheen_color;\n    float _5793 = _5430.sheen_roughness;\n    float _5794 = _5430.anisotropy;\n    float _5795 = _5430.anisotropy_rotation;\n    float _5796 = _5430.specular;\n    float _5797 = _5430.ior;\n    vec3 _5798 = _5430.specular_color;\n    float _5799 = _5430.transmission;\n    float _5800 = _5430.thickness;\n    vec3 _5801 = _5430.attenuation_color;\n    float _5802 = _5430.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing);\n    Surface param_3 = _5430;\n    surface(param_2, param_3);\n    _5783 = param_3.albedo;\n    _5784 = param_3.alpha;\n    _5785 = param_3.normal;\n    _5786 = param_3.metallic;\n    _5787 = param_3.roughness;\n    _5788 = param_3.occlusion;\n    _5789 = param_3.emission;\n    _5790 = param_3.clearcoat;\n    _5791 = param_3.clearcoat_roughness;\n    _5792 = param_3.sheen_color;\n    _5793 = param_3.sheen_roughness;\n    _5794 = param_3.anisotropy;\n    _5795 = param_3.anisotropy_rotation;\n    _5796 = param_3.specular;\n    _5797 = param_3.ior;\n    _5798 = param_3.specular_color;\n    _5799 = param_3.transmission;\n    _5800 = param_3.thickness;\n    _5801 = param_3.attenuation_color;\n    _5802 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5752;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5783 = param_6;\n    _5785 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5783;\n    }\n    else\n    {\n        vec3 _5469 = _5785;\n        vec3 _5470 = normalize(_5469);\n        _5785 = _5470;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing);\n        Surface param_9 = Surface(_5783, _5784, _5470, _5786, _5787, _5788, _5789, _5790, _5791, _5792, _5793, _5794, _5795, _5796, _5797, _5798, _5799, _5800, _5801, _5802);\n        vec3 _5481 = lighting(param_8, param_9);\n        result = _5481;\n    }\n    vec3 _5485 = result;\n    vec3 _5486 = _5485 + _5789;\n    result = _5486;\n    vec3 param_10 = _5486;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5495 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5502;\n    if (!_5495)\n    {\n        _5502 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5502 = _5495;\n    }\n    if (_5502)\n    {\n        vec3 _5511 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5517 = dot(_5511, fa_mesh_fs_params[9].xyz);\n        bool _5521 = fa_mesh_fs_params[9].w > 0.5;\n        float _5522;\n        if (_5521)\n        {\n            _5522 = _5517;\n        }\n        else\n        {\n            _5522 = length(_5511);\n        }\n        float _5534 = _5522 - fa_mesh_fs_params[8].x;\n        if (_5534 > 0.0)\n        {\n            float _5543 = fa_mesh_fs_params[7].w * _5534;\n            float tau = _5543 * _5543;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5559;\n                if (_5521)\n                {\n                    _5559 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5517);\n                }\n                else\n                {\n                    _5559 = fa_mesh_fs_params[0].y;\n                }\n                float _5580 = mix(_5559, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5522, 0.0, 1.0));\n                float _5584 = fa_world_pos.y - _5580;\n                float _5589 = _5580 - fa_mesh_fs_params[8].z;\n                float _5594 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5597 = _5589 <= 0.0;\n                bool _5598 = !_5597;\n                bool _5604;\n                if (_5598)\n                {\n                    _5604 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5604 = _5597;\n                }\n                float _5605;\n                if (_5604)\n                {\n                    _5605 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5605 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5589, 80.0));\n                }\n                bool _5632;\n                if (_5598)\n                {\n                    _5632 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5632 = _5597;\n                }\n                float _5633;\n                if (_5632)\n                {\n                    _5633 = fa_mesh_fs_params[8].y * _5589;\n                }\n                else\n                {\n                    _5633 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5589, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5658 = _5594 <= 0.0;\n                bool _5665;\n                if (!_5658)\n                {\n                    _5665 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5665 = _5658;\n                }\n                float _5666;\n                if (_5665)\n                {\n                    _5666 = fa_mesh_fs_params[8].y * _5594;\n                }\n                else\n                {\n                    _5666 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5594, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5693;\n                if (abs(_5584) < 0.001000000047497451305389404296875)\n                {\n                    _5693 = _5605;\n                }\n                else\n                {\n                    _5693 = (_5666 - _5633) / _5584;\n                }\n                tau += (_5534 * max(_5693, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5784);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_468",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2121",
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
            "inst_name": "_5035",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3885[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1397 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1436 = vec4(world_pos, 1.0);\n    float _1442 = dot(fa_mesh_fs_params[16], _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1464 = vec2(dot(fa_mesh_fs_params[14], _1436), dot(fa_mesh_fs_params[15], _1436)) / vec2(_1442);\n    int _1468 = int(fa_mesh_fs_params[18].x);\n    int _1472 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1548 = fa_cluster_texel(param);\n    return ivec2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4719 = fa_cluster_lookup(param);\n    fa_cl_slot = _4719.x;\n    fa_cl_local = _4719.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5096 = fa_linear_to_srgb(param);\n        c = _5096;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5104 = fa_srgb_to_linear(param_1);\n            c = _5104;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    vec3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    vec3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    vec3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5135 = fa_tex_fix(param_2, param_3);\n    vec4 _6274 = base_t;\n    _6274.x = _5135.x;\n    _6274.y = _5135.y;\n    _6274.z = _5135.z;\n    base_t = _6274;\n    vec4 _5149 = (_6274 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6080 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5181 = fa_tex_fix(param_6, param_7);\n        vec3 _5184 = (_5181 * 2.0) - vec3(1.0);\n        vec2 _5189 = _5184.xy * fa_mesh_fs_params[6].x;\n        vec3 _6282 = _5184;\n        _6282.x = _5189.x;\n        _6282.y = _5189.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6282;\n        _6080 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5217 = fa_tex_fix(param_12, param_13);\n    vec4 _6285 = mrt;\n    _6285.x = _5217.x;\n    _6285.y = _5217.y;\n    _6285.z = _5217.z;\n    mrt = _6285;\n    vec4 _5245 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5245.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5256 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5286 = fa_tex_fix(param_20, param_21);\n    float _6085 = fa_mesh_fs_params[20].x;\n    float _6086 = fa_mesh_fs_params[20].y;\n    float _6089 = fa_mesh_fs_params[20].z;\n    float _6088 = fa_mesh_fs_params[21].w;\n    float _6091 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6085 *= _5256.y;\n            _6086 *= _5256.z;\n            _6088 *= _5245.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6089 *= mrt.x;\n            _6091 *= mrt.w;\n        }\n    }\n    return Surface(_5149.xyz, _5149.w, _6080, clamp(fa_mesh_fs_params[5].x * _5217.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5217.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5256.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5286), _6085, _6086, fa_mesh_fs_params[21].xyz, _6088, _6089, fa_mesh_fs_params[20].w, _6091, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1628 = rect.zw - rect.xy;\n    vec2 _1632 = _1628 * atlas;\n    vec2 _1636 = ddx * _1632;\n    vec2 _1640 = ddy * _1632;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1628), clamp(0.5 * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1673 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    vec3 _1686 = dFdx(world_pos);\n    vec3 _1689 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1707;\n    vec4 _1711 = fa_light_texel(param_1);\n    vec2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    vec4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1734 = int(_1693.z);\n    vec3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        vec4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        vec4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        vec4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        vec4 _1794 = fa_light_texel(param_7);\n        vec3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        vec3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        vec3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0, 1.0);\n        if (_1852 <= 0.0)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5 - abs(_1816)) * 10.0, 0.0, 1.0) * _1852) * _1769.x;\n        vec2 _1880 = vec2(_1802 + 0.5, 0.5 - _1809);\n        vec2 _1890 = vec2(dot(_1797, _1686), dot(_1804, _1686));\n        vec2 _1900 = vec2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        vec4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        vec4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        vec4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            vec4 param_11 = _1910;\n            vec2 param_12 = _1880;\n            vec2 param_13 = _1714;\n            vec2 param_14 = _1890;\n            vec2 param_15 = _1900;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5) && (_1724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1951 = fa_dc_to_linear(param_16);\n                vec4 _6168 = tx;\n                _6168.x = _1951.x;\n                _6168.y = _1951.y;\n                _6168.z = _1951.z;\n                tx = _6168;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1872 * tex_a) * _1905.w, 0.0, 1.0)));\n        if (_1915.z > _1915.x)\n        {\n            vec4 param_17 = _1915;\n            vec2 param_18 = _1880;\n            vec2 param_19 = _1714;\n            vec2 param_20 = _1890;\n            vec2 param_21 = _1900;\n            vec4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5)\n            {\n                vec3 param_22 = _1995.xyz;\n                vec3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            vec3 _2014 = (_1999 * 2.0) - vec3(1.0);\n            vec2 _2019 = _2014.xy * _1769.y;\n            vec3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            vec3 _2044 = normalize(normal);\n            normal = normalize(mix(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125)) + (_2041 - (_2044 * dot(_2044, _2041)))), vec3(clamp(_1872 * (_1925 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4689;\n    if (fa_lm.z > 0.5)\n    {\n        _4689 = 0.0;\n    }\n    else\n    {\n        _4689 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4700 = _4689 < 1.0;\n    bool _4706;\n    if (_4700)\n    {\n        int param = li;\n        _4706 = fa_light_baked(param);\n    }\n    else\n    {\n        _4706 = _4700;\n    }\n    return _4706 ? _4689 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _646 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _659 = (c - (ru * hx)) - p;\n        vec3 _665 = ru * (2.0 * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0, 1.0);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06 * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0, 1.0);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    vec3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0)\n        {\n            q = p + (r * _746);\n        }\n    }\n    vec3 _759 = q - c;\n    vec2 xy = vec2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10)\n    {\n        _581 = atan(_570, _566) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _581 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_581 - floor(_581)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _812;\n    vec4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    vec4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _840 = _816 && (_828 > 2.5);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5;\n    vec3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            vec4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5)\n            {\n                int param_4 = _812 + 4;\n                vec4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                vec4 _871 = fa_light_texel(param_5);\n                vec2 param_6 = _856.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _901 = _820.xyz;\n        vec3 _903 = _901 - world_pos;\n        vec3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _812 + 4;\n            vec4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            vec4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            vec4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            vec3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            vec3 r = vec3(0.0);\n            vec3 _967 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            vec3 param_13 = _901;\n            vec3 param_14 = _948;\n            vec3 param_15 = _930.xyz;\n            vec3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / vec3(max(_1015, 9.9999997473787516355514526367188e-05));\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875);\n        float _1035 = clamp(1.0 - (_1029 * _1029), 0.0, 1.0);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5;\n        if ((_828 > 1.5) && _1048)\n        {\n            int param_22 = _812 + 2;\n            vec4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            vec4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5)\n            {\n                cos_inner = mix(_1066, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5))\n        {\n            int param_24 = _812 + 6;\n            vec4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5)\n            {\n                vec3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                vec3 _1118 = fa_light_texel(param_25).xyz;\n                vec3 _1122 = fa_light_texel(param_26).xyz;\n                vec3 _1131 = vec3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                vec3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1162 = vec2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / vec2(max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05));\n                int _1166 = _1135 / 3;\n                vec2 param_31 = _1096.xy + (vec2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1162.x), 0.5 - (0.5 * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            vec4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                vec2 param_37 = _1196.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                vec4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                vec4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    vec4 _1265 = fa_light_texel(param_44);\n                    vec3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    vec4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    vec4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        vec3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5 / max(dot(_1287, _1269) * (sqrt(max(1.0 - (_1294 * _1294), 0.0)) / max(_1294, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1243.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1287, _1274.xyz) * _1310), 0.5 - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5)\n                    {\n                        vec2 param_49 = _1248.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1269;\n                        vec3 param_52 = _1274.xyz;\n                        vec3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5886 = _825.xyz * atten;\n    if (_816)\n    {\n        _5886 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5) && (_828 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5886, atten, 1.0, dist, _1379);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4918 = n < 0;\n    bool _4925;\n    if (!_4918)\n    {\n        _4925 = n >= fa_light_count();\n    }\n    else\n    {\n        _4925 = _4918;\n    }\n    if (_4925)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4933 = fa_cl_light(param);\n    int param_1 = _4933;\n    float _4937 = fa_baked_keep(param_1);\n    if (_4937 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4933;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4953 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4953.direction, _4953.color * _4937, _4953.attenuation * _4937, _4953.shadow, _4953._distance, _4953.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2224 = vec2(cos(_2218), sin(_2218));\n    vec2 dir = _2224;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5) * 0.0625) * _2252;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2271));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0) * unit) * _2323) / texel_m, 1.5, 16.0);\n        dir = _2224;\n    }\n    float lit = 0.0;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5) / float(_2349)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2368));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2135 = fa_shadows[24].w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2414 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2419 = clamp(dot(n, l), 0.0, 1.0);\n    float _2425 = sqrt(1.0 - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2425)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2414);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2414;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2893)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2975 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2975;\n        if (_2975 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3000;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3000 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3000 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3019 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3000, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3030 = clamp((_2908 - (fa_shadow_split_at(param_7) - _3019)) / _3019, 0.0, 1.0);\n        if (_3030 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2893)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3051 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3051;\n                if (_3051 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3030);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4425 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4432;\n    if (!_4425)\n    {\n        _4432 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4432 = _4425;\n    }\n    if (_4432)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4445 = fa_light_texel(param);\n    float _4446 = _4445.y;\n    float len = _4446;\n    if (_4446 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4458 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4468 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4458);\n    if (_4468 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4474 = len;\n    float _4477 = min(_4474, 0.89999997615814208984375 * dist);\n    len = _4477;\n    float _4482 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4458);\n    float _4487 = _4482 + (0.5 * _4477);\n    vec3 _4493 = world + (gn * _4482);\n    float _4495 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4559;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4510 = (float(k) + _4495) * 0.083333335816860198974609375;\n        vec3 _4518 = _4493 + (l * (_4510 * len));\n        vec4 _4524 = vec4(_4518, 1.0);\n        float _4530 = dot(fa_mesh_fs_params[28], _4524);\n        if (_4530 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4550 = vec2(dot(fa_mesh_fs_params[26], _4524), dot(fa_mesh_fs_params[27], _4524)) / vec2(_4530);\n        float _4554 = _4550.x * 0.5;\n        float _4555 = _4554 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4559 = (_4550.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4559 = 0.5 - (_4550.y * 0.5);\n        }\n        bool _4575 = _4555 < 0.0;\n        bool _4582;\n        if (!_4575)\n        {\n            _4582 = _4555 >= 1.0;\n        }\n        else\n        {\n            _4582 = _4575;\n        }\n        bool _4589;\n        if (!_4582)\n        {\n            _4589 = _4559 < 0.0;\n        }\n        else\n        {\n            _4589 = _4582;\n        }\n        bool _4596;\n        if (!_4589)\n        {\n            _4596 = _4559 >= 1.0;\n        }\n        else\n        {\n            _4596 = _4589;\n        }\n        if (_4596)\n        {\n            break;\n        }\n        vec4 _4623 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4555, _4559) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4623.w < 0.5)\n        {\n            continue;\n        }\n        float _4642 = (dot(fa_mesh_fs_params[29].xyz, _4518) + fa_mesh_fs_params[29].w) - _4623.x;\n        if ((_4642 > _4482) && (_4642 < _4487))\n        {\n            occ = max(occ, (1.0 - (_4510 * _4510)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4555, 0.5 - _4554), min(_4559, 1.0 - _4559))));\n        }\n    }\n    return 1.0 - (occ * _4468);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4745 = fa_baked_keep(param);\n    if (_4745 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4771 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6032 = _4771.color;\n    float _6033 = _4771.attenuation;\n    float _6034 = _4771.shadow;\n    bool _4774 = _4771.type == 0;\n    if (_4774 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4771.direction;\n        float _4785 = fa_shadow_factor(param_5, param_6);\n        _6034 = _4785;\n        _6032 *= _4785;\n    }\n    else\n    {\n        bool _4796 = _4771.type != 0;\n        bool _4802;\n        if (_4796)\n        {\n            _4802 = _6033 > 0.0;\n        }\n        else\n        {\n            _4802 = _4796;\n        }\n        if (_4802)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4771.direction;\n            float _4821 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6034 = _4821;\n            _6032 *= _4821;\n        }\n    }\n    bool _4831 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4837;\n    if (_4831)\n    {\n        _4837 = _6033 > 0.0;\n    }\n    else\n    {\n        _4837 = _4831;\n    }\n    if (_4837)\n    {\n        float _4844;\n        if (_4774)\n        {\n            _4844 = 1000000000.0;\n        }\n        else\n        {\n            _4844 = _4771._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4771.direction;\n        float param_18 = _4844;\n        float _4862 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6034 *= _4862;\n        _6032 *= _4862;\n    }\n    float _4875 = _6033;\n    float _4876 = _4875 * _4745;\n    _6033 = _4876;\n    vec3 _4880 = _6032;\n    vec3 _4881 = _4880 * _4745;\n    _6032 = _4881;\n    return LightSample(_4771.direction, _4881, _4876, _6034, _4771._distance, _4771.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4892 = n < 0;\n    bool _4899;\n    if (!_4892)\n    {\n        _4899 = n >= fa_light_count();\n    }\n    else\n    {\n        _4899 = _4892;\n    }\n    if (_4899)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4914 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4914;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3810 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3818 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3821 = int(_3810);\n    int _3824 = int(_3818);\n    float _3834 = _3818 - float(_3824);\n    int _3890 = (_3821 * 9) + _3824;\n    int _3910 = ((_3821 + 1) * 9) + _3824;\n    return mix(mix(_3885[_3890], _3885[_3890 + 1], _3834), mix(_3885[_3910], _3885[_3910 + 1], _3834), _3810 - float(_3821));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5898 = false;\n    float _5899 = 1.0;\n    float _5900 = 1.0;\n    float _5901 = 1.0;\n    float _5902 = 0.0;\n    float _5903 = 0.0;\n    float _5904 = 0.0;\n    float _5905 = 0.0;\n    float _5907 = 1.0;\n    bool _5908 = false;\n    vec3 _5909 = vec3(0.0);\n    float _5910 = 1.0;\n    float _5911 = 1.0;\n    float _5912 = 1.0;\n    float _5913 = 0.0;\n    float _5914 = 0.0;\n    vec3 _5915 = vec3(1.0, 0.0, 0.0);\n    vec3 _5916 = vec3(0.0, 0.0, 1.0);\n    float _5917 = 1.0;\n    float _5918 = 1.0;\n    float _3961 = clamp(s.specular, 0.0, 1.0);\n    float _3965 = clamp(s.ior, 1.0, 3.0);\n    bool _3970 = (_3961 != 1.0) || (_3965 != 1.5);\n    bool _3979;\n    if (!_3970)\n    {\n        _3979 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3979 = _3970;\n    }\n    if (_3979)\n    {\n        float _3987 = (_3965 - 1.0) / (_3965 + 1.0);\n        f0 = mix(min(vec3(_3987 * _3987) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3961, s.albedo, vec3(metallic));\n        _5899 = mix(_3961, 1.0, metallic);\n        _5898 = true;\n    }\n    float _4014 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4014 > 0.0)\n    {\n        float _4022 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5902 = _4014;\n        _5903 = _4022;\n        float _4029 = _4022 * _4022;\n        _5904 = _4029;\n        _5905 = _4029 * _4029;\n        float _4041 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5907 = _4041;\n        _5900 = 1.0 - (_4014 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4041, 0.0, 1.0), 5.0))));\n        _5898 = true;\n    }\n    vec3 _4060 = max(s.sheen_color, vec3(0.0));\n    float _4069 = max(_4060.x, max(_4060.y, _4060.z));\n    if (_4069 > 0.0)\n    {\n        float _4077 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5908 = true;\n        _5909 = _4060;\n        _5910 = _4077;\n        _5911 = _4077 * _4077;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4077;\n        float _4094 = fa_sheen_albedo(param, param_1);\n        _5913 = _4094;\n        _5912 = 1.0 - min(_4069 * _4094, 1.0);\n        _5898 = true;\n    }\n    _5901 = _5900 * _5912;\n    float _4113 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4113 != 0.0)\n    {\n        vec3 _4128 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4128;\n        if (dot(_4128, _4128) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4140 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4140.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4140.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4140.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4144 = t;\n        vec3 _4145 = normalize(_4144);\n        t = _4145;\n        vec3 _4170 = normalize((_4145 * cos(s.anisotropy_rotation)) + ((cross(n, _4145) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5915 = _4170;\n        _5916 = cross(n, _4170);\n        float _4180 = roughness * roughness;\n        float _4186 = mix(_4180, 1.0, _4113 * _4113);\n        bool _4188 = _4113 > 0.0;\n        _5917 = _4188 ? _4186 : _4180;\n        _5918 = _4188 ? _4180 : _4186;\n        _5914 = _4113;\n        _5898 = true;\n    }\n    return FaLayers(_5898, _5899, _5900, _5901, _5902, _5903, _5904, _5905, i.world_normal, _5907, _5908, _5909, _5910, _5911, _5912, _5913, _5914, _5915, _5916, _5917, _5918);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3742 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3745 = _3742.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3745 * _3745, exp2((-9.27999973297119140625) * ndv)) * _3745) + _3742.y)) + _3742.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3177 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3180 = _3177.x;\n    float _3182 = _3177.z;\n    vec2 e = vec2(_3180, _3182);\n    if (_3177.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3182)) * ((_3180 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3180)) * ((_3182 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3229;\n    if (lv == 0)\n    {\n        _3229 = 0.0;\n    }\n    else\n    {\n        _3229 = res + 2.0;\n    }\n    float _3239;\n    if (lv == 0)\n    {\n        _3239 = 0.0;\n    }\n    else\n    {\n        _3239 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3229, _3239)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3285;\n    if (res > 64.5)\n    {\n        _3285 = 5.0;\n    }\n    else\n    {\n        _3285 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3300 = clamp(rough, 0.0, 1.0) * (_3285 - 1.0);\n    int _3307 = int(min(floor(_3300), _3285 - 2.0));\n    float _3312 = _3300 - float(_3307);\n    vec3 param = d;\n    vec2 _3316 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3307;\n    vec2 param_4 = _3316;\n    vec3 _3326 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3312 < 0.00200000009499490261077880859375)\n    {\n        return _3326;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3307 + 1;\n    vec2 param_8 = _3316;\n    return mix(_3326, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3312));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3364 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3371 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3378 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3384 = dot(bx.xyz, d);\n    float _3388 = dot(by.xyz, d);\n    float _3392 = dot(bz.xyz, d);\n    float _3398;\n    if (_3384 > 9.9999999747524270787835121154785e-07)\n    {\n        _3398 = (1.0 - _3364) / _3384;\n    }\n    else\n    {\n        float _3412;\n        if (_3384 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3412 = ((-1.0) - _3364) / _3384;\n        }\n        else\n        {\n            _3412 = 1000000015047466219876688855040.0;\n        }\n        _3398 = _3412;\n    }\n    float tx = _3398;\n    float _3429;\n    if (_3388 > 9.9999999747524270787835121154785e-07)\n    {\n        _3429 = (1.0 - _3371) / _3388;\n    }\n    else\n    {\n        float _3442;\n        if (_3388 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3442 = ((-1.0) - _3371) / _3388;\n        }\n        else\n        {\n            _3442 = 1000000015047466219876688855040.0;\n        }\n        _3429 = _3442;\n    }\n    float ty = _3429;\n    float _3458;\n    if (_3392 > 9.9999999747524270787835121154785e-07)\n    {\n        _3458 = (1.0 - _3378) / _3392;\n    }\n    else\n    {\n        float _3471;\n        if (_3392 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3471 = ((-1.0) - _3378) / _3392;\n        }\n        else\n        {\n            _3471 = 1000000015047466219876688855040.0;\n        }\n        _3458 = _3471;\n    }\n    float _3483 = tx;\n    float _3486 = (_3483 > 0.0) ? _3483 : 1000000015047466219876688855040.0;\n    tx = _3486;\n    float _3487 = ty;\n    float _3490 = (_3487 > 0.0) ? _3487 : 1000000015047466219876688855040.0;\n    ty = _3490;\n    float _3500 = min(_3486, min(_3490, (_3458 > 0.0) ? _3458 : 1000000015047466219876688855040.0));\n    if (_3500 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3516 = (fa_world_pos + (d * _3500)) - posw.xyz;\n    vec3 _3521;\n    if (dot(_3516, _3516) > 1.0000000133514319600180897396058e-10)\n    {\n        _3521 = normalize(_3516);\n    }\n    else\n    {\n        _3521 = d;\n    }\n    return _3521;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3567 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3567 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3597 = rough * rough;\n            float _3628 = 0.60000002384185791015625 * _3597;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3597)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3628, 0.0500000007450580596923828125 + _3628, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3597 * 0.60000002384185791015625));\n        }\n        outc = base * _3567;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3687 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3687 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3719 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3719 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4221;\n        if (L.aniso >= 0.0)\n        {\n            _4221 = L.b;\n        }\n        else\n        {\n            _4221 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4221, v), _4221), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4257 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4257.x) + (vec3(L.f90) * _4257.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4315 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4315.x) + _4315.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3784 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3784.x) + vec3(_3784.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4354 = clamp(s.metallic, 0.0, 1.0);\n    float _4358 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4365 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4354));\n    vec3 f0 = _4365;\n    vec3 _4369 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4369;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4354;\n    float param_5 = _4358;\n    vec3 param_6 = _4365;\n    FaLayers _4386 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4386.on)\n    {\n        FaLayers param_7 = _4386;\n        vec3 param_8 = _4369;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4358;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4369;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4358;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4984 = fa_light_unshadowed(param, param_1);\n        float _4992 = dot(_4984.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4992 > bestPower)\n        {\n            bestPower = _4992;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5021 = fa_light(param_2, param_3);\n        float _5029;\n        if (dot(s.normal, _5021.direction) > 0.5)\n        {\n            _5029 = 1.0;\n        }\n        else\n        {\n            _5029 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5021.color) * _5029);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3075 = int(fa_shadows[25].x + 0.5);\n    float _3085 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3090 = _3075 > 0;\n    bool _3099;\n    if (_3090)\n    {\n        int param = _3075 - 1;\n        _3099 = _3085 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3099 = _3090;\n    }\n    if (_3099)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3105 = _3075 > 1;\n        bool _3112;\n        if (_3105)\n        {\n            _3112 = _3085 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3112 = _3105;\n        }\n        if (_3112)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3118 = _3075 > 2;\n        bool _3125;\n        if (_3118)\n        {\n            _3125 = _3085 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3125 = _3118;\n        }\n        if (_3125)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3131 = _3075 > 3;\n        bool _3138;\n        if (_3131)\n        {\n            _3138 = _3085 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3138 = _3131;\n        }\n        if (_3138)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5752 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5752 = -_5752;\n    }\n    vec3 _5422 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing);\n    Surface _5430 = fa_standard_surface(param_1);\n    vec3 _5783 = _5430.albedo;\n    float _5784 = _5430.alpha;\n    vec3 _5785 = _5430.normal;\n    float _5786 = _5430.metallic;\n    float _5787 = _5430.roughness;\n    float _5788 = _5430.occlusion;\n    vec3 _5789 = _5430.emission;\n    float _5790 = _5430.clearcoat;\n    float _5791 = _5430.clearcoat_roughness;\n    vec3 _5792 = _5430.sheen_color;\n    float _5793 = _5430.sheen_roughness;\n    float _5794 = _5430.anisotropy;\n    float _5795 = _5430.anisotropy_rotation;\n    float _5796 = _5430.specular;\n    float _5797 = _5430.ior;\n    vec3 _5798 = _5430.specular_color;\n    float _5799 = _5430.transmission;\n    float _5800 = _5430.thickness;\n    vec3 _5801 = _5430.attenuation_color;\n    float _5802 = _5430.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing);\n    Surface param_3 = _5430;\n    surface(param_2, param_3);\n    _5783 = param_3.albedo;\n    _5784 = param_3.alpha;\n    _5785 = param_3.normal;\n    _5786 = param_3.metallic;\n    _5787 = param_3.roughness;\n    _5788 = param_3.occlusion;\n    _5789 = param_3.emission;\n    _5790 = param_3.clearcoat;\n    _5791 = param_3.clearcoat_roughness;\n    _5792 = param_3.sheen_color;\n    _5793 = param_3.sheen_roughness;\n    _5794 = param_3.anisotropy;\n    _5795 = param_3.anisotropy_rotation;\n    _5796 = param_3.specular;\n    _5797 = param_3.ior;\n    _5798 = param_3.specular_color;\n    _5799 = param_3.transmission;\n    _5800 = param_3.thickness;\n    _5801 = param_3.attenuation_color;\n    _5802 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5752;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5783 = param_6;\n    _5785 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5783;\n    }\n    else\n    {\n        vec3 _5469 = _5785;\n        vec3 _5470 = normalize(_5469);\n        _5785 = _5470;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5752, fa_world_tangent, fa_uv, fa_vertex_color, _5422, gl_FrontFacing);\n        Surface param_9 = Surface(_5783, _5784, _5470, _5786, _5787, _5788, _5789, _5790, _5791, _5792, _5793, _5794, _5795, _5796, _5797, _5798, _5799, _5800, _5801, _5802);\n        vec3 _5481 = lighting(param_8, param_9);\n        result = _5481;\n    }\n    vec3 _5485 = result;\n    vec3 _5486 = _5485 + _5789;\n    result = _5486;\n    vec3 param_10 = _5486;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5495 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5502;\n    if (!_5495)\n    {\n        _5502 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5502 = _5495;\n    }\n    if (_5502)\n    {\n        vec3 _5511 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5517 = dot(_5511, fa_mesh_fs_params[9].xyz);\n        bool _5521 = fa_mesh_fs_params[9].w > 0.5;\n        float _5522;\n        if (_5521)\n        {\n            _5522 = _5517;\n        }\n        else\n        {\n            _5522 = length(_5511);\n        }\n        float _5534 = _5522 - fa_mesh_fs_params[8].x;\n        if (_5534 > 0.0)\n        {\n            float _5543 = fa_mesh_fs_params[7].w * _5534;\n            float tau = _5543 * _5543;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5559;\n                if (_5521)\n                {\n                    _5559 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5517);\n                }\n                else\n                {\n                    _5559 = fa_mesh_fs_params[0].y;\n                }\n                float _5580 = mix(_5559, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5522, 0.0, 1.0));\n                float _5584 = fa_world_pos.y - _5580;\n                float _5589 = _5580 - fa_mesh_fs_params[8].z;\n                float _5594 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5597 = _5589 <= 0.0;\n                bool _5598 = !_5597;\n                bool _5604;\n                if (_5598)\n                {\n                    _5604 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5604 = _5597;\n                }\n                float _5605;\n                if (_5604)\n                {\n                    _5605 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5605 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5589, 80.0));\n                }\n                bool _5632;\n                if (_5598)\n                {\n                    _5632 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5632 = _5597;\n                }\n                float _5633;\n                if (_5632)\n                {\n                    _5633 = fa_mesh_fs_params[8].y * _5589;\n                }\n                else\n                {\n                    _5633 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5589, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5658 = _5594 <= 0.0;\n                bool _5665;\n                if (!_5658)\n                {\n                    _5665 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5665 = _5658;\n                }\n                float _5666;\n                if (_5665)\n                {\n                    _5666 = fa_mesh_fs_params[8].y * _5594;\n                }\n                else\n                {\n                    _5666 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5594, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5693;\n                if (abs(_5584) < 0.001000000047497451305389404296875)\n                {\n                    _5693 = _5605;\n                }\n                else\n                {\n                    _5693 = (_5666 - _5633) / _5584;\n                }\n                tau += (_5534 * max(_5693, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5784);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_468",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2121",
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
            "inst_name": "_5035",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _831 = base_t;\n    _831.x = _227.x;\n    _831.y = _227.y;\n    _831.z = _227.z;\n    base_t = _831;\n    vec4 _243 = (_831 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _786 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _839 = _281;\n        _839.x = _286.x;\n        _839.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _842 = mrt;\n    _842.x = _315.x;\n    _842.y = _315.y;\n    _842.z = _315.z;\n    mrt = _842;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _791 = fa_mesh_fs_params[20].x;\n    float _792 = fa_mesh_fs_params[20].y;\n    float _795 = fa_mesh_fs_params[20].z;\n    float _794 = fa_mesh_fs_params[21].w;\n    float _797 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _791 *= _357.y;\n            _792 *= _357.z;\n            _794 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _786, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _791, _792, fa_mesh_fs_params[21].xyz, _794, _795, fa_mesh_fs_params[20].w, _797, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _681 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _831 = base_t;\n    _831.x = _227.x;\n    _831.y = _227.y;\n    _831.z = _227.z;\n    base_t = _831;\n    vec4 _243 = (_831 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _786 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _839 = _281;\n        _839.x = _286.x;\n        _839.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _842 = mrt;\n    _842.x = _315.x;\n    _842.y = _315.y;\n    _842.z = _315.z;\n    mrt = _842;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _791 = fa_mesh_fs_params[20].x;\n    float _792 = fa_mesh_fs_params[20].y;\n    float _795 = fa_mesh_fs_params[20].z;\n    float _794 = fa_mesh_fs_params[21].w;\n    float _797 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _791 *= _357.y;\n            _792 *= _357.z;\n            _794 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _786, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _791, _792, fa_mesh_fs_params[21].xyz, _794, _795, fa_mesh_fs_params[20].w, _797, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _681 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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

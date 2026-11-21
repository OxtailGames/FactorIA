{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "ae26515a48b1a8d2e7a58b8583b7398bc5ad5b1e5314aaacf65f28e91c149fe7",
  "slang": "glsl430",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4353[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1591 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1598;\n    if (!_1591)\n    {\n        _1598 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1598 = _1591;\n    }\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    bool _1613;\n    if (!_1606)\n    {\n        _1613 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1613 = _1606;\n    }\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    if (_1620)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1630 = vec4(world_pos, 1.0);\n    float _1636 = dot(fa_mesh_fs_params[16], _1630);\n    if (!(_1636 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1658 = vec2(dot(fa_mesh_fs_params[14], _1630), dot(fa_mesh_fs_params[15], _1630)) / vec2(_1636);\n    int _1662 = int(fa_mesh_fs_params[18].x);\n    int _1666 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1666) + clamp(int(floor(((_1658.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1666 - 1)) * _1662)) + clamp(int(floor(((_1658.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1662 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1742 = fa_cluster_texel(param);\n    return ivec2(int(_1742.x), int(_1742.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5828 = fa_cluster_lookup(param);\n    fa_cl_slot = _5828.x;\n    fa_cl_local = _5828.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6961 = fa_linear_to_srgb(param);\n        c = _6961;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6969 = fa_srgb_to_linear(param_1);\n            c = _6969;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _535;\n    if (i.front_facing)\n    {\n        _535 = i.world_normal;\n    }\n    else\n    {\n        _535 = -i.world_normal;\n    }\n    vec3 _559 = normalize(i.world_tangent.xyz - (_535 * dot(_535, i.world_tangent.xyz)));\n    vec3 _586 = normalize(((_559 * m.x) + ((cross(_535, _559) * i.world_tangent.w) * m.y)) + (_535 * m.z));\n    vec3 _589;\n    if (i.front_facing)\n    {\n        _589 = _586;\n    }\n    else\n    {\n        _589 = -_586;\n    }\n    return _589;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7000 = fa_tex_fix(param_2, param_3);\n    vec4 _9261 = base_t;\n    _9261.x = _7000.x;\n    _9261.y = _7000.y;\n    _9261.z = _7000.z;\n    base_t = _9261;\n    vec4 _7014 = (_9261 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9045 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7046 = fa_tex_fix(param_6, param_7);\n        vec3 _7049 = (_7046 * 2.0) - vec3(1.0);\n        vec2 _7054 = _7049.xy * fa_mesh_fs_params[6].x;\n        vec3 _9269 = _7049;\n        _9269.x = _7054.x;\n        _9269.y = _7054.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9269;\n        _9045 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7082 = fa_tex_fix(param_12, param_13);\n    vec4 _9272 = mrt;\n    _9272.x = _7082.x;\n    _9272.y = _7082.y;\n    _9272.z = _7082.z;\n    mrt = _9272;\n    vec4 _7110 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7110.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7121 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7151 = fa_tex_fix(param_20, param_21);\n    float _9050 = fa_mesh_fs_params[20].x;\n    float _9051 = fa_mesh_fs_params[20].y;\n    float _9054 = fa_mesh_fs_params[20].z;\n    float _9053 = fa_mesh_fs_params[21].w;\n    float _9056 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9050 *= _7121.y;\n            _9051 *= _7121.z;\n            _9053 *= _7110.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9054 *= mrt.x;\n            _9056 *= mrt.w;\n        }\n    }\n    return Surface(_7014.xyz, _7014.w, _9045, clamp(fa_mesh_fs_params[5].x * _7082.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7082.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7121.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7151), _9050, _9051, fa_mesh_fs_params[21].xyz, _9053, _9054, fa_mesh_fs_params[20].w, _9056, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1822 = rect.zw - rect.xy;\n    vec2 _1826 = _1822 * atlas;\n    vec2 _1830 = ddx * _1826;\n    vec2 _1834 = ddy * _1826;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1822), clamp(0.5 * log2(max(max(dot(_1830, _1830), dot(_1834, _1834)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1867 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1874;\n    if (!_1867)\n    {\n        _1874 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1874 = _1867;\n    }\n    if (_1874)\n    {\n        return;\n    }\n    vec3 _1880 = dFdx(world_pos);\n    vec3 _1883 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1887 = fa_cluster_texel(param);\n    int _1891 = int(_1887.w);\n    if (_1891 < 1)\n    {\n        return;\n    }\n    int _1901 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1901;\n    vec4 _1905 = fa_light_texel(param_1);\n    vec2 _1908 = _1905.yz;\n    int _1912 = int(_1905.w);\n    int param_2 = _1901 + 1;\n    vec4 _1917 = fa_light_texel(param_2);\n    float _1918 = _1917.x;\n    int _1924 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1928 = int(_1887.z);\n    vec3 _2193;\n    for (int k = 0; k < _1891; k++)\n    {\n        int _1941 = _1928 + k;\n        int param_3 = _1912 + (_1941 >> 2);\n        int _1958 = (_1901 + 2) + (int(fa_light_texel(param_3)[_1941 & 3]) * 7);\n        int param_4 = _1958 + 6;\n        vec4 _1963 = fa_light_texel(param_4);\n        if (((int(_1963.w + 0.5) >> _1924) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1958;\n        vec4 _1978 = fa_light_texel(param_5);\n        int param_6 = _1958 + 1;\n        vec4 _1983 = fa_light_texel(param_6);\n        int param_7 = _1958 + 2;\n        vec4 _1988 = fa_light_texel(param_7);\n        vec3 _1991 = _1978.xyz;\n        float _1996 = dot(_1991, world_pos) + _1978.w;\n        vec3 _1998 = _1983.xyz;\n        float _2003 = dot(_1998, world_pos) + _1983.w;\n        vec3 _2005 = _1988.xyz;\n        float _2010 = dot(_2005, world_pos) + _1988.w;\n        bool _2015 = abs(_1996) > 0.5;\n        bool _2023;\n        if (!_2015)\n        {\n            _2023 = abs(_2003) > 0.5;\n        }\n        else\n        {\n            _2023 = _2015;\n        }\n        bool _2031;\n        if (!_2023)\n        {\n            _2031 = abs(_2010) > 0.5;\n        }\n        else\n        {\n            _2031 = _2023;\n        }\n        if (_2031)\n        {\n            continue;\n        }\n        float _2046 = clamp(dot(geo_normal, normalize(_2005)) * _1963.z, 0.0, 1.0);\n        if (_2046 <= 0.0)\n        {\n            continue;\n        }\n        float _2066 = (clamp((0.5 - abs(_2010)) * 10.0, 0.0, 1.0) * _2046) * _1963.x;\n        vec2 _2074 = vec2(_1996 + 0.5, 0.5 - _2003);\n        vec2 _2084 = vec2(dot(_1991, _1880), dot(_1998, _1880));\n        vec2 _2094 = vec2(dot(_1991, _1883), dot(_1998, _1883));\n        int param_8 = _1958 + 5;\n        vec4 _2099 = fa_light_texel(param_8);\n        int param_9 = _1958 + 3;\n        vec4 _2104 = fa_light_texel(param_9);\n        int param_10 = _1958 + 4;\n        vec4 _2109 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2099.xyz;\n        bool _2119 = _2104.z > _2104.x;\n        if (_2119)\n        {\n            vec4 param_11 = _2104;\n            vec2 param_12 = _2074;\n            vec2 param_13 = _1908;\n            vec2 param_14 = _2084;\n            vec2 param_15 = _2094;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1918 > 0.5) && (_1918 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2145 = fa_dc_to_linear(param_16);\n                vec4 _9133 = tx;\n                _9133.x = _2145.x;\n                _9133.y = _2145.y;\n                _9133.z = _2145.z;\n                tx = _9133;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2066 * tex_a) * _2099.w, 0.0, 1.0)));\n        if (_2109.z > _2109.x)\n        {\n            vec4 param_17 = _2109;\n            vec2 param_18 = _2074;\n            vec2 param_19 = _1908;\n            vec2 param_20 = _2084;\n            vec2 param_21 = _2094;\n            vec4 _2189 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1918 > 1.5)\n            {\n                vec3 param_22 = _2189.xyz;\n                vec3 _2199 = fa_dc_to_srgb(param_22);\n                _2193 = _2199;\n            }\n            else\n            {\n                _2193 = _2189.xyz;\n            }\n            vec3 _2208 = (_2193 * 2.0) - vec3(1.0);\n            vec2 _2213 = _2208.xy * _1963.y;\n            vec3 _2235 = (normalize(_1991) * _2213.x) + (normalize(_1998) * _2213.y);\n            vec3 _2238 = normalize(normal);\n            normal = normalize(mix(_2238, normalize((_2238 * max(_2208.z, 0.0500000007450580596923828125)) + (_2235 - (_2238 * dot(_2238, _2235)))), vec3(clamp(_2066 * (_2119 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4278 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4286 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4289 = int(_4278);\n    int _4292 = int(_4286);\n    float _4302 = _4286 - float(_4292);\n    int _4357 = (_4289 * 9) + _4292;\n    int _4377 = ((_4289 + 1) * 9) + _4292;\n    return mix(mix(_4353[_4357], _4353[_4357 + 1], _4302), mix(_4353[_4377], _4353[_4377 + 1], _4302), _4278 - float(_4289));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _8968 = false;\n    float _8969 = 1.0;\n    float _8970 = 1.0;\n    float _8971 = 1.0;\n    float _8972 = 0.0;\n    float _8973 = 0.0;\n    float _8974 = 0.0;\n    float _8975 = 0.0;\n    float _8977 = 1.0;\n    bool _8978 = false;\n    vec3 _8979 = vec3(0.0);\n    float _8980 = 1.0;\n    float _8981 = 1.0;\n    float _8982 = 1.0;\n    float _8983 = 0.0;\n    float _8984 = 0.0;\n    vec3 _8985 = vec3(1.0, 0.0, 0.0);\n    vec3 _8986 = vec3(0.0, 0.0, 1.0);\n    float _8987 = 1.0;\n    float _8988 = 1.0;\n    float _4428 = clamp(s.specular, 0.0, 1.0);\n    float _4432 = clamp(s.ior, 1.0, 3.0);\n    bool _4437 = (_4428 != 1.0) || (_4432 != 1.5);\n    bool _4446;\n    if (!_4437)\n    {\n        _4446 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4446 = _4437;\n    }\n    if (_4446)\n    {\n        float _4454 = (_4432 - 1.0) / (_4432 + 1.0);\n        f0 = mix(min(vec3(_4454 * _4454) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4428, s.albedo, vec3(metallic));\n        _8969 = mix(_4428, 1.0, metallic);\n        _8968 = true;\n    }\n    float _4481 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4481 > 0.0)\n    {\n        float _4489 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _8972 = _4481;\n        _8973 = _4489;\n        float _4496 = _4489 * _4489;\n        _8974 = _4496;\n        _8975 = _4496 * _4496;\n        float _4508 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _8977 = _4508;\n        _8970 = 1.0 - (_4481 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4508, 0.0, 1.0), 5.0))));\n        _8968 = true;\n    }\n    vec3 _4527 = max(s.sheen_color, vec3(0.0));\n    float _4536 = max(_4527.x, max(_4527.y, _4527.z));\n    if (_4536 > 0.0)\n    {\n        float _4544 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _8978 = true;\n        _8979 = _4527;\n        _8980 = _4544;\n        _8981 = _4544 * _4544;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4544;\n        float _4561 = fa_sheen_albedo(param, param_1);\n        _8983 = _4561;\n        _8982 = 1.0 - min(_4536 * _4561, 1.0);\n        _8968 = true;\n    }\n    _8971 = _8970 * _8982;\n    float _4580 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4580 != 0.0)\n    {\n        vec3 _4595 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4595;\n        if (dot(_4595, _4595) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4607 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4607.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4607.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4607.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4611 = t;\n        vec3 _4612 = normalize(_4611);\n        t = _4612;\n        vec3 _4637 = normalize((_4612 * cos(s.anisotropy_rotation)) + ((cross(n, _4612) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _8985 = _4637;\n        _8986 = cross(n, _4637);\n        float _4647 = roughness * roughness;\n        float _4653 = mix(_4647, 1.0, _4580 * _4580);\n        bool _4655 = _4580 > 0.0;\n        _8987 = _4655 ? _4653 : _4647;\n        _8988 = _4655 ? _4647 : _4653;\n        _8984 = _4580;\n        _8968 = true;\n    }\n    return FaLayers(_8968, _8969, _8970, _8971, _8972, _8973, _8974, _8975, i.world_normal, _8977, _8978, _8979, _8980, _8981, _8982, _8983, _8984, _8985, _8986, _8987, _8988);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3446 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3446;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4059 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4064 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4059 > 0.0005000000237487256526947021484375)\n    {\n        if (_4064)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4059;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4059;\n        }\n    }\n    bool _4115 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4115)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4146 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4146)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4064 || _4115) || _4146)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3466 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3469 = _3466.x;\n    float _3471 = _3466.z;\n    vec2 e = vec2(_3469, _3471);\n    if (_3466.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3471)) * ((_3469 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3469)) * ((_3471 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7261 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7266 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7271 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7276 = fa_light_texel(param_3);\n    bool _7279 = _7276.z < 0.5;\n    bool _7287;\n    if (!_7279)\n    {\n        _7287 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7287 = _7279;\n    }\n    if (_7287)\n    {\n        return vec3(0.0);\n    }\n    float _7294 = max(_7261.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7297 = _7266.xyz;\n    vec3 _7301 = _7261.xyz;\n    vec3 _7305 = (fa_world_pos - _7301) / vec3(_7294);\n    vec3 _7314 = min(_7305 + vec3(0.5), (_7297 - vec3(0.5)) - _7305);\n    float _7323 = min(_7314.x, min(_7314.y, _7314.z));\n    if (!(_7323 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7338 = _7297 - vec3(1.0);\n    vec3 _7339 = clamp(_7305, vec3(0.0), _7338);\n    vec3 _7347 = min(floor(_7339), max(_7297 - vec3(2.0), vec3(0.0)));\n    vec3 _7351 = _7339 - _7347;\n    vec3 _7362 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7294));\n    int _7367 = int(_7271.y + 0.5);\n    float _7372 = 0.3257350027561187744140625 * n.y;\n    float _7376 = 0.3257350027561187744140625 * n.z;\n    float _7380 = 0.3257350027561187744140625 * n.x;\n    float _7387 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7394 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7403 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7410 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7423 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7430 = 8 + int(_7276.w);\n    float _7457;\n    float _7470;\n    float _7484;\n    for (int k = 0; k < _7430; k++)\n    {\n        float _7443 = float(k & 1);\n        float _7447 = float((k >> 1) & 1);\n        float _7451 = float((k >> 2) & 1);\n        if (_7443 > 0.5)\n        {\n            _7457 = _7351.x;\n        }\n        else\n        {\n            _7457 = 1.0 - _7351.x;\n        }\n        if (_7447 > 0.5)\n        {\n            _7470 = _7351.y;\n        }\n        else\n        {\n            _7470 = 1.0 - _7351.y;\n        }\n        if (_7451 > 0.5)\n        {\n            _7484 = _7351.z;\n        }\n        else\n        {\n            _7484 = 1.0 - _7351.z;\n        }\n        float _7494 = (_7457 * _7470) * _7484;\n        if (!(_7494 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7507 = min(_7347 + vec3(_7443, _7447, _7451), _7338);\n        int _7527 = int(((_7271.x + _7507.x) + (_7266.x * (_7507.y + (_7266.y * _7507.z)))) + 0.5);\n        vec2 _7542 = vec2(float(_7527 % _7367) * 10.0, 1024.0 + (float(_7527 / _7367) * 11.0));\n        vec2 param_4 = _7542 + vec2(9.5, 10.5);\n        vec4 _7550 = fa_gi_fetch(param_4);\n        bool _7553 = _7550.y < 0.5;\n        bool _7562;\n        if (!_7553)\n        {\n            _7562 = _7550.x > _7276.y;\n        }\n        else\n        {\n            _7562 = _7553;\n        }\n        if (_7562)\n        {\n            continue;\n        }\n        vec3 _7574 = _7362 - (_7301 + (_7507 * _7294));\n        float _7577 = length(_7574);\n        vec3 _7583 = _7574 / vec3(max(_7577, 9.9999997473787516355514526367188e-05));\n        float _7593 = max(9.9999997473787516355514526367188e-05, (dot(-_7583, n) + 1.0) * 0.5);\n        float w = _7494 * (_7593 * _7593);\n        vec3 param_5 = _7583;\n        vec2 param_6 = (_7542 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7612 = fa_gi_fetch(param_6);\n        float _7619 = _7577 / max(_7271.z, 9.9999997473787516355514526367188e-05);\n        float _7622 = _7612.x;\n        if (_7619 > _7622)\n        {\n            float _7635 = max(_7612.y - (_7622 * _7622), 0.0);\n            float _7640 = _7619 - _7622;\n            float _7649 = _7635 / max(_7635 + (_7640 * _7640), 9.9999999600419720025001879548654e-13);\n            w *= ((_7649 * _7649) * _7649);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7542 + vec2(0.5, 10.5);\n        vec2 param_8 = _7542 + vec2(1.5, 10.5);\n        vec2 param_9 = _7542 + vec2(2.5, 10.5);\n        vec2 param_10 = _7542 + vec2(3.5, 10.5);\n        vec2 param_11 = _7542 + vec2(4.5, 10.5);\n        vec2 param_12 = _7542 + vec2(5.5, 10.5);\n        vec2 param_13 = _7542 + vec2(6.5, 10.5);\n        vec2 param_14 = _7542 + vec2(7.5, 10.5);\n        vec2 param_15 = _7542 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7372)) + (fa_gi_fetch(param_9).xyz * _7376)) + (fa_gi_fetch(param_10).xyz * _7380)) + (fa_gi_fetch(param_11).xyz * _7387)) + (fa_gi_fetch(param_12).xyz * _7394)) + (fa_gi_fetch(param_13).xyz * _7403)) + (fa_gi_fetch(param_14).xyz * _7410)) + (fa_gi_fetch(param_15).xyz * _7423)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7323 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7774;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7774 = _7276.x;\n    }\n    else\n    {\n        _7774 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7271.w * _7774);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7798 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7803 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7808 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7808) && (k < 8); k++)\n    {\n        int param = _7803 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7798;\n        vec3 _7833 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7838 = param_3 * left;\n        acc += (_7833 * _7838);\n        left -= _7838;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7867 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7867;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5798;\n    if (fa_lm.z > 0.5)\n    {\n        _5798 = 0.0;\n    }\n    else\n    {\n        _5798 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5809 = _5798 < 1.0;\n    bool _5815;\n    if (_5809)\n    {\n        int param = li;\n        _5815 = fa_light_baked(param);\n    }\n    else\n    {\n        _5815 = _5809;\n    }\n    return _5815 ? _5798 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _840 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _853 = (c - (ru * hx)) - p;\n        vec3 _859 = ru * (2.0 * hx);\n        float _865 = max(dot(_859, _859), 9.9999999392252902907785028219223e-09);\n        float _869 = dot(_853, _859);\n        float t = clamp((-_869) / _865, 0.0, 1.0);\n        if (_840)\n        {\n            float _884 = dot(r, _859);\n            float _890 = _865 - (_884 * _884);\n            if (abs(_890) > (9.9999997473787516355514526367188e-06 * _865))\n            {\n                t = clamp(((dot(r, _853) * _884) - _869) / _890, 0.0, 1.0);\n            }\n        }\n        return (p + _853) + (_859 * t);\n    }\n    vec3 q = p;\n    float _922 = dot(r, axis);\n    bool _930;\n    if (_840)\n    {\n        _930 = abs(_922) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _930 = _840;\n    }\n    if (_930)\n    {\n        float _940 = dot(c - p, axis) / _922;\n        if (_940 > 0.0)\n        {\n            q = p + (r * _940);\n        }\n    }\n    vec3 _953 = q - c;\n    vec2 xy = vec2(dot(_953, ru), dot(_953, uu));\n    if (shape > 0.5)\n    {\n        float _968 = length(xy);\n        if (_968 > hx)\n        {\n            xy *= (hx / _968);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _601 = abs(d);\n    float _603 = _601.x;\n    float _605 = _601.y;\n    bool _606 = _603 >= _605;\n    bool _614;\n    if (_606)\n    {\n        _614 = _603 >= _601.z;\n    }\n    else\n    {\n        _614 = _606;\n    }\n    int _615;\n    if (_614)\n    {\n        _615 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _630;\n        if (_605 >= _601.z)\n        {\n            _630 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _630 = (d.z > 0.0) ? 4 : 5;\n        }\n        _615 = _630;\n    }\n    return _615;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _760 = dot(d, right);\n    float _764 = dot(d, up);\n    float _775;\n    if (((_760 * _760) + (_764 * _764)) > 1.0000000133514319600180897396058e-10)\n    {\n        _775 = atan(_764, _760) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _775 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_775 - floor(_775)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1006 = fa_light_base(param);\n    bool _1010 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1006;\n    vec4 _1014 = fa_light_texel(param_1);\n    int param_2 = _1006 + 1;\n    vec4 _1019 = fa_light_texel(param_2);\n    float _1022 = _1019.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1034 = _1010 && (_1022 > 2.5);\n    fa_light_is_area = _1034;\n    bool _1036 = _1022 < 0.5;\n    vec3 l;\n    if (_1036)\n    {\n        l = normalize(_1014.xyz);\n        if (_1010)\n        {\n            int param_3 = _1006 + 6;\n            vec4 _1050 = fa_light_texel(param_3);\n            if (_1050.z > 0.5)\n            {\n                int param_4 = _1006 + 4;\n                vec4 _1060 = fa_light_texel(param_4);\n                int param_5 = _1006 + 5;\n                vec4 _1065 = fa_light_texel(param_5);\n                vec2 param_6 = _1050.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1060.xyz) * _1060.w, (-dot(world_pos, _1065.xyz)) * _1065.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1095 = _1014.xyz;\n        vec3 _1097 = _1095 - world_pos;\n        vec3 to_light = _1097;\n        float _1100 = length(_1097);\n        float reach = _1100;\n        bool front = true;\n        if (_1034)\n        {\n            int param_8 = _1006 + 7;\n            reach = max(_1100 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1006 + 4;\n            vec4 _1124 = fa_light_texel(param_9);\n            int param_10 = _1006 + 5;\n            vec4 _1129 = fa_light_texel(param_10);\n            int param_11 = _1006 + 6;\n            vec4 _1134 = fa_light_texel(param_11);\n            float _1135 = _1134.w;\n            int param_12 = _1006 + 2;\n            vec3 _1142 = normalize(fa_light_texel(param_12).xyz);\n            bool _1144 = _1135 > 1.5;\n            bool _1152;\n            if (!_1144)\n            {\n                _1152 = dot(_1142, to_light) < 0.0;\n            }\n            else\n            {\n                _1152 = _1144;\n            }\n            front = _1152;\n            vec3 r = vec3(0.0);\n            vec3 _1161 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1165 = dot(n, n) > 0.5;\n            bool _1173;\n            if (_1165)\n            {\n                _1173 = dot(_1161, _1161) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1173 = _1165;\n            }\n            if (_1173)\n            {\n                r = reflect(-normalize(_1161), normalize(n));\n            }\n            vec3 param_13 = _1095;\n            vec3 param_14 = _1142;\n            vec3 param_15 = _1124.xyz;\n            vec3 param_16 = _1129.xyz;\n            float param_17 = _1124.w;\n            float param_18 = _1129.w;\n            float param_19 = _1135;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1209 = length(to_light);\n        dist = _1209;\n        l = to_light / vec3(max(_1209, 9.9999997473787516355514526367188e-05));\n        float _1223 = reach / max(_1014.w, 0.001000000047497451305389404296875);\n        float _1229 = clamp(1.0 - (_1223 * _1223), 0.0, 1.0);\n        float _1231;\n        if (front)\n        {\n            _1231 = _1229 * _1229;\n        }\n        else\n        {\n            _1231 = 0.0;\n        }\n        atten = _1231;\n        bool _1242 = _1022 < 2.5;\n        if ((_1022 > 1.5) && _1242)\n        {\n            int param_22 = _1006 + 2;\n            vec4 _1250 = fa_light_texel(param_22);\n            float _1260 = _1250.w;\n            int param_23 = _1006 + 3;\n            vec4 _1265 = fa_light_texel(param_23);\n            float _1266 = _1265.x;\n            float cos_inner = _1266;\n            if (_1266 > 1.5)\n            {\n                cos_inner = mix(_1260, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1260, cos_inner, dot(-l, normalize(_1250.xyz)));\n        }\n        if (_1010 && (_1022 < 1.5))\n        {\n            int param_24 = _1006 + 6;\n            vec4 _1290 = fa_light_texel(param_24);\n            if (_1290.z > 0.5)\n            {\n                vec3 _1298 = -to_light;\n                int param_25 = _1006 + 4;\n                int param_26 = _1006 + 5;\n                vec3 _1312 = fa_light_texel(param_25).xyz;\n                vec3 _1316 = fa_light_texel(param_26).xyz;\n                vec3 _1325 = vec3(dot(_1298, _1312), dot(_1298, _1316), dot(_1298, cross(_1312, _1316)));\n                vec3 param_27 = _1325;\n                int _1329 = fa_cube_face(param_27);\n                int param_28 = _1329;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1356 = vec2(dot(_1325, cross(param_29, param_30)), dot(_1325, param_30)) / vec2(max(dot(_1325, param_29), 9.9999997473787516355514526367188e-05));\n                int _1360 = _1329 / 3;\n                vec2 param_31 = _1290.xy + (vec2(float(_1329 - (_1360 * 3)), float(_1360)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1356.x), 0.5 - (0.5 * _1356.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1006 + 7;\n            vec4 _1390 = fa_light_texel(param_33);\n            if (_1390.z > 0.5)\n            {\n                int param_34 = _1006 + 2;\n                int param_35 = _1006 + 4;\n                int param_36 = _1006 + 5;\n                vec2 param_37 = _1390.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1010 && _1242)\n            {\n                int param_42 = _1006 + 6;\n                vec4 _1437 = fa_light_texel(param_42);\n                int param_43 = _1006 + 7;\n                vec4 _1442 = fa_light_texel(param_43);\n                bool _1445 = _1437.z > 0.5;\n                bool _1452;\n                if (!_1445)\n                {\n                    _1452 = _1442.z > 0.5;\n                }\n                else\n                {\n                    _1452 = _1445;\n                }\n                if (_1452)\n                {\n                    int param_44 = _1006 + 2;\n                    vec4 _1459 = fa_light_texel(param_44);\n                    vec3 _1463 = normalize(_1459.xyz);\n                    int param_45 = _1006 + 4;\n                    vec4 _1468 = fa_light_texel(param_45);\n                    int param_46 = _1006 + 5;\n                    vec4 _1473 = fa_light_texel(param_46);\n                    if (_1445)\n                    {\n                        vec3 _1481 = -to_light;\n                        float _1488 = _1459.w;\n                        float _1504 = 0.5 / max(dot(_1481, _1463) * (sqrt(max(1.0 - (_1488 * _1488), 0.0)) / max(_1488, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1437.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1481, _1468.xyz) * _1504), 0.5 - (dot(_1481, _1473.xyz) * _1504));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1442.z > 0.5)\n                    {\n                        vec2 param_49 = _1442.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1463;\n                        vec3 param_52 = _1468.xyz;\n                        vec3 param_53 = _1473.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8956 = _1019.xyz * atten;\n    if (_1010)\n    {\n        _8956 *= fa_light_tint;\n    }\n    int _1573;\n    if (_1036)\n    {\n        _1573 = 0;\n    }\n    else\n    {\n        _1573 = ((_1022 > 1.5) && (_1022 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8956, atten, 1.0, dist, _1573);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2305;\n    if (i == 0)\n    {\n        _2305 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2321;\n        if (i == 1)\n        {\n            _2321 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2329;\n            if (i == 2)\n            {\n                _2329 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2329 = fa_shadows[24].w;\n            }\n            _2321 = _2329;\n        }\n        _2305 = _2321;\n    }\n    return _2305;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2362 = fa_shadow_depth(param, param_1);\n    float _2366;\n    if (conv.x < 0.5)\n    {\n        _2366 = _2362;\n    }\n    else\n    {\n        _2366 = (conv.y * conv.z) / (conv.z - (_2362 * (conv.z - conv.y)));\n    }\n    return _2366;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2412 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2418 = vec2(cos(_2412), sin(_2412));\n    vec2 dir = _2418;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2427;\n        if (k < 0.0)\n        {\n            _2427 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2427 = k;\n        }\n        float _2446 = clamp((_2427 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2465 = sqrt((float(i) + 0.5) * 0.0625) * _2446;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2465));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2479 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2479 < (zr - (_2465 * plane)))\n            {\n                sum += _2479;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2507 = sum / cnt;\n        float _2517;\n        if (k < 0.0)\n        {\n            _2517 = (-k) / max(_2507, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2517 = k;\n        }\n        radius = clamp(((max(zr - _2507, 0.0) * unit) * _2517) / texel_m, 1.5, 16.0);\n        dir = _2418;\n    }\n    float lit = 0.0;\n    int _2543 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2543; i_1++)\n    {\n        float _2562 = sqrt((float(i_1) + 0.5) / float(_2543)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2562));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2562 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2543);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2608 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2613 = clamp(dot(n, l), 0.0, 1.0);\n    float _2619 = sqrt(1.0 - (_2613 * _2613));\n    float _2627 = min(_2619 / max(_2613, 0.20000000298023223876953125), 4.0);\n    float _2632;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2632 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2632 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2657 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2632 * _2619)), 1.0);\n    float _2664 = _2657.x;\n    bool _2667 = _2664 < fa_shadows[ci * 1 + 16].x;\n    bool _2676;\n    if (!_2667)\n    {\n        _2676 = _2664 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2676 = _2667;\n    }\n    bool _2685;\n    if (!_2676)\n    {\n        _2685 = _2657.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2685 = _2676;\n    }\n    bool _2694;\n    if (!_2685)\n    {\n        _2694 = _2657.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2694 = _2685;\n    }\n    bool _2701;\n    if (!_2694)\n    {\n        _2701 = _2657.z > 1.0;\n    }\n    else\n    {\n        _2701 = _2694;\n    }\n    if (_2701)\n    {\n        return -1.0;\n    }\n    float _2709;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2709 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2709 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2657.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2657.z - ((_2709 * (1.0 + (0.5 * _2627))) / _2608);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2608;\n    float param_5 = _2608 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2627, 3.0)) * 0.5) / _2608;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3087 = int(fa_shadows[25].x + 0.5);\n    if (_3087 < 1)\n    {\n        return 1.0;\n    }\n    float _3102 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3087 - 1;\n    if (_3102 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3114 = _3087 > 1;\n    bool _3121;\n    if (_3114)\n    {\n        _3121 = _3102 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3121 = _3114;\n    }\n    if (_3121)\n    {\n        ci = 1;\n    }\n    bool _3125 = _3087 > 2;\n    bool _3132;\n    if (_3125)\n    {\n        _3132 = _3102 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3132 = _3125;\n    }\n    if (_3132)\n    {\n        ci = 2;\n    }\n    bool _3136 = _3087 > 3;\n    bool _3143;\n    if (_3136)\n    {\n        _3143 = _3102 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3143 = _3136;\n    }\n    if (_3143)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3087)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3169 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3169;\n        if (_3169 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3194;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3194 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3194 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3213 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3194, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3224 = clamp((_3102 - (fa_shadow_split_at(param_7) - _3213)) / _3213, 0.0, 1.0);\n        if (_3224 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3087)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3245 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3245;\n                if (_3245 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3224);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2767 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2774;\n    if (!_2767)\n    {\n        _2774 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2774 = _2767;\n    }\n    if (_2774)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2787 = fa_light_texel(param);\n    float _2788 = _2787.x;\n    if (_2788 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2797 = int(_2788 + 0.5);\n    int param_1 = _2797;\n    vec4 _2801 = fa_light_texel(param_1);\n    int param_2 = _2797 + 1;\n    vec4 _2806 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2809 = _2801.y;\n    if (_2809 > 0.0)\n    {\n        float _2826 = 1.0 - smoothstep(0.75 * _2809, _2809, length(world - fa_shadows[27].xyz));\n        fade = _2826;\n        if (_2826 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2801.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2850 = (_2797 + 2) + (face * 6);\n    int param_4 = _2850;\n    int param_5 = _2850 + 1;\n    int param_6 = _2850 + 3;\n    vec4 _2864 = fa_light_texel(param_6);\n    int param_7 = _2850 + 4;\n    vec4 _2869 = fa_light_texel(param_7);\n    int param_8 = _2850 + 5;\n    vec4 _2874 = fa_light_texel(param_8);\n    float _2886 = _2874.x * max(dot(_2864, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2891 = clamp(dot(n, l), 0.0, 1.0);\n    float _2914 = clamp(dot(n, _2864.xyz), -1.0, 1.0);\n    float _2933 = min(sqrt(1.0 - (_2914 * _2914)) / max(abs(dot(n, world - lpos)) / max(dot(_2864, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2936 = _2806.y;\n    float _2938;\n    if (_2936 > 0.0)\n    {\n        _2938 = _2936;\n    }\n    else\n    {\n        _2938 = 1.5 * _2886;\n    }\n    vec4 _2958 = vec4(world + (n * (_2938 * sqrt(1.0 - (_2891 * _2891)))), 1.0);\n    float _2962 = dot(_2864, _2958);\n    float _2965 = _2874.y;\n    if (_2962 < _2965)\n    {\n        return 1.0;\n    }\n    vec2 _2980 = vec2(dot(fa_light_texel(param_4), _2958), dot(fa_light_texel(param_5), _2958)) / vec2(_2962);\n    float _2982 = _2980.x;\n    bool _2985 = _2982 < _2869.x;\n    bool _2994;\n    if (!_2985)\n    {\n        _2994 = _2982 > _2869.z;\n    }\n    else\n    {\n        _2994 = _2985;\n    }\n    bool _3003;\n    if (!_2994)\n    {\n        _3003 = _2980.y < _2869.y;\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    bool _3012;\n    if (!_3003)\n    {\n        _3012 = _2980.y > _2869.w;\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        return 1.0;\n    }\n    float _3018 = _2806.x;\n    float _3020;\n    if (_3018 > 0.0)\n    {\n        _3020 = _3018;\n    }\n    else\n    {\n        _3020 = 1.5 * _2886;\n    }\n    vec2 param_9 = _2980;\n    vec4 param_10 = _2869;\n    float param_11 = _2962 - (_3020 * (1.0 + (0.5 * _2933)));\n    float param_12 = _2886;\n    float param_13 = 1.0;\n    float param_14 = _2874.z * 0.25;\n    float param_15 = (_2886 * min(_2933, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2965, _2874.z);\n    int param_17 = int(_2801.z + 0.5);\n    float param_18 = _2801.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5171 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5178;\n    if (!_5171)\n    {\n        _5178 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5178 = _5171;\n    }\n    if (_5178)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5191 = fa_light_texel(param);\n    float _5192 = _5191.y;\n    float len = _5192;\n    if (_5192 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5204 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5214 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5204);\n    if (_5214 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5220 = len;\n    float _5223 = min(_5220, 0.89999997615814208984375 * dist);\n    len = _5223;\n    float _5228 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5204);\n    float _5233 = _5228 + (0.5 * _5223);\n    vec3 _5239 = world + (gn * _5228);\n    float _5241 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5305;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5256 = (float(k) + _5241) * 0.083333335816860198974609375;\n        vec3 _5264 = _5239 + (l * (_5256 * len));\n        vec4 _5270 = vec4(_5264, 1.0);\n        float _5276 = dot(fa_mesh_fs_params[28], _5270);\n        if (_5276 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5296 = vec2(dot(fa_mesh_fs_params[26], _5270), dot(fa_mesh_fs_params[27], _5270)) / vec2(_5276);\n        float _5300 = _5296.x * 0.5;\n        float _5301 = _5300 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5305 = (_5296.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5305 = 0.5 - (_5296.y * 0.5);\n        }\n        bool _5321 = _5301 < 0.0;\n        bool _5328;\n        if (!_5321)\n        {\n            _5328 = _5301 >= 1.0;\n        }\n        else\n        {\n            _5328 = _5321;\n        }\n        bool _5335;\n        if (!_5328)\n        {\n            _5335 = _5305 < 0.0;\n        }\n        else\n        {\n            _5335 = _5328;\n        }\n        bool _5342;\n        if (!_5335)\n        {\n            _5342 = _5305 >= 1.0;\n        }\n        else\n        {\n            _5342 = _5335;\n        }\n        if (_5342)\n        {\n            break;\n        }\n        vec4 _5369 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5301, _5305) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5369.w < 0.5)\n        {\n            continue;\n        }\n        float _5388 = (dot(fa_mesh_fs_params[29].xyz, _5264) + fa_mesh_fs_params[29].w) - _5369.x;\n        if ((_5388 > _5228) && (_5388 < _5233))\n        {\n            occ = max(occ, (1.0 - (_5256 * _5256)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5301, 0.5 - _5300), min(_5305, 1.0 - _5305))));\n        }\n    }\n    return 1.0 - (occ * _5214);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5854 = fa_baked_keep(param);\n    if (_5854 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5880 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9025 = _5880.color;\n    float _9026 = _5880.attenuation;\n    float _9027 = _5880.shadow;\n    bool _5883 = _5880.type == 0;\n    if (_5883 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5880.direction;\n        float _5894 = fa_shadow_factor(param_5, param_6);\n        _9027 = _5894;\n        _9025 *= _5894;\n    }\n    else\n    {\n        bool _5905 = _5880.type != 0;\n        bool _5911;\n        if (_5905)\n        {\n            _5911 = _9026 > 0.0;\n        }\n        else\n        {\n            _5911 = _5905;\n        }\n        if (_5911)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5880.direction;\n            float _5930 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9027 = _5930;\n            _9025 *= _5930;\n        }\n    }\n    bool _5940 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5946;\n    if (_5940)\n    {\n        _5946 = _9026 > 0.0;\n    }\n    else\n    {\n        _5946 = _5940;\n    }\n    if (_5946)\n    {\n        float _5953;\n        if (_5883)\n        {\n            _5953 = 1000000000.0;\n        }\n        else\n        {\n            _5953 = _5880._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5880.direction;\n        float param_18 = _5953;\n        float _5971 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9027 *= _5971;\n        _9025 *= _5971;\n    }\n    float _5984 = _9026;\n    float _5985 = _5984 * _5854;\n    _9026 = _5985;\n    vec3 _5989 = _9025;\n    vec3 _5990 = _5989 * _5854;\n    _9025 = _5990;\n    return LightSample(_5880.direction, _5990, _5985, _9027, _5880._distance, _5880.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6024 = v - (n * dot(v, n));\n    vec3 t = _6024;\n    float _6028 = dot(_6024, _6024);\n    float l2 = _6028;\n    if (_6028 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6038;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6038 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6038 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6038;\n        l2 = dot(_6038, _6038);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6073 = dot(a, a);\n    float _6077 = dot(b, b);\n    if ((_6073 < 1.0000000195414813782625560981111e-24) || (_6077 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6091 = a * inversesqrt(_6073);\n    vec3 _6096 = b * inversesqrt(_6077);\n    float _6100 = dot(_6091, _6096);\n    float _6103 = abs(_6100);\n    float g = (((((((((((0.0416471660137176513671875 * _6103) - 0.1924748718738555908203125) * _6103) + 0.4179156124591827392578125) * _6103) - 0.616057217121124267578125) * _6103) + 0.777722418308258056640625) * _6103) - 0.999542415142059326171875) * _6103) + 1.570791721343994140625;\n    if (_6100 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6100 * _6100), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6091, _6096) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6160 = a.z > 0.0;\n    bool _6164 = b.z > 0.0;\n    if (_6160 && _6164)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6160 != _6164)\n        {\n            vec3 _6199 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6199.z = 0.0;\n            if (_6160)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6199;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6199;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6199;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6199;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6248 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6274 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6300 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6326 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6248;\n    vec3 param_1 = _6274;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6274;\n    vec3 param_7 = _6300;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6300;\n    vec3 param_13 = _6326;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6326;\n    vec3 param_19 = _6248;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6475 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6499 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6515 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6475;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6499;\n    vec4 param_9 = m;\n    vec3 param_10 = _6475;\n    vec3 param_11 = _6499;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6515;\n    vec4 param_14 = m;\n    vec3 param_15 = _6475;\n    vec3 param_16 = _6515;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6573 = fa_light_base(param);\n    int param_1 = _6573;\n    int param_2 = _6573 + 1;\n    int param_3 = _6573 + 2;\n    int param_4 = _6573 + 4;\n    vec4 _6595 = fa_light_texel(param_4);\n    int param_5 = _6573 + 5;\n    vec4 _6600 = fa_light_texel(param_5);\n    int param_6 = _6573 + 6;\n    vec4 _6605 = fa_light_texel(param_6);\n    float _6606 = _6605.w;\n    vec3 _6611 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6613 = _6606 < 1.5;\n    bool _6620;\n    if (_6613)\n    {\n        _6620 = dot(normalize(fa_light_texel(param_3).xyz), _6611) >= 0.0;\n    }\n    else\n    {\n        _6620 = _6613;\n    }\n    if (_6620)\n    {\n        return vec3(0.0);\n    }\n    bool _6629 = (_6606 > 0.5) && _6613;\n    float _6633 = _6629 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6636 = _6595.xyz;\n    float _6638 = _6595.w;\n    vec3 _6644 = _6600.xyz;\n    float _6646 = _6600.w;\n    vec3 up = _6644 * (_6646 * _6633);\n    float _6652;\n    if (_6629)\n    {\n        _6652 = (3.1415927410125732421875 * _6638) * _6638;\n    }\n    else\n    {\n        _6652 = (4.0 * _6638) * _6646;\n    }\n    if (_6606 > 1.5)\n    {\n        vec3 _6678 = cross(_6636, -_6611);\n        vec3 perp = _6678;\n        float _6682 = dot(_6678, _6678);\n        vec3 _6685;\n        if (_6682 > 1.0000000133514319600180897396058e-10)\n        {\n            _6685 = perp * inversesqrt(_6682);\n        }\n        else\n        {\n            _6685 = _6644;\n        }\n        perp = _6685;\n        up = _6685 * _6646;\n    }\n    float _6706 = max(_6652, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6716 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6716;\n    vec3 param_10 = n;\n    vec3 param_11 = _6611;\n    vec3 _6724 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6716;\n    vec3 param_13 = n;\n    vec3 param_14 = _6636 * (_6638 * _6633);\n    vec3 _6732 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6716;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6740 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6606;\n    vec3 param_20 = _6724;\n    vec3 param_21 = _6732;\n    vec3 param_22 = _6740;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6759 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6759;\n    vec2 param_26 = _6759 + vec2(64.0, 0.0);\n    vec4 _6769 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6606;\n    vec3 param_29 = _6724;\n    vec3 param_30 = _6732;\n    vec3 param_31 = _6740;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6769.x) + ((vec3(f90) - f0) * _6769.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6611, _6611)) + _6706) / _6706) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4908 = 1.0 / alpha;\n    return ((2.0 + _4908) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4908)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4943 = max(dot(L.nc, l), 0.0);\n    float _4949 = max(dot(L.nc, h), 0.0);\n    float _4958 = ((_4949 * _4949) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4958) * _4958)) * (0.5 / max(mix((2.0 * _4943) * L.coat_ndv, _4943 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4943)) * _4943;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6837;\n    if (L.sheen_on)\n    {\n        _6837 = L.sheen_scale;\n    }\n    else\n    {\n        _6837 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6837);\n    vec3 _6850 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6861 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6870 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6850), 0.0);\n        float param_13 = _6870;\n        float param_14 = ndv;\n        result += ((L.sheen * _6861) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6870)) * _6870) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6850;\n        float param_18 = max(dot(v, _6850), 0.0);\n        result += (_6861 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4811 = tdh / at;\n    float _4815 = bdh / ab;\n    float _4827 = ((_4811 * _4811) + (_4815 * _4815)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4827) * _4827);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5007 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5086 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5086) * _5086);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5007);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5007));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4210 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4213 = _4210.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4213 * _4213, exp2((-9.27999973297119140625) * ndv)) * _4213) + _4210.y)) + _4210.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3518;\n    if (lv == 0)\n    {\n        _3518 = 0.0;\n    }\n    else\n    {\n        _3518 = res + 2.0;\n    }\n    float _3528;\n    if (lv == 0)\n    {\n        _3528 = 0.0;\n    }\n    else\n    {\n        _3528 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3518, _3528)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3574;\n    if (res > 64.5)\n    {\n        _3574 = 5.0;\n    }\n    else\n    {\n        _3574 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3589 = clamp(rough, 0.0, 1.0) * (_3574 - 1.0);\n    int _3596 = int(min(floor(_3589), _3574 - 2.0));\n    float _3601 = _3589 - float(_3596);\n    vec3 param = d;\n    vec2 _3605 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3596;\n    vec2 param_4 = _3605;\n    vec3 _3615 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3601 < 0.00200000009499490261077880859375)\n    {\n        return _3615;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3596 + 1;\n    vec2 param_8 = _3605;\n    return mix(_3615, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3601));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3688 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3695 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3702 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3708 = dot(bx.xyz, d);\n    float _3712 = dot(by.xyz, d);\n    float _3716 = dot(bz.xyz, d);\n    float _3722;\n    if (_3708 > 9.9999999747524270787835121154785e-07)\n    {\n        _3722 = (1.0 - _3688) / _3708;\n    }\n    else\n    {\n        float _3736;\n        if (_3708 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3736 = ((-1.0) - _3688) / _3708;\n        }\n        else\n        {\n            _3736 = 1000000015047466219876688855040.0;\n        }\n        _3722 = _3736;\n    }\n    float tx = _3722;\n    float _3753;\n    if (_3712 > 9.9999999747524270787835121154785e-07)\n    {\n        _3753 = (1.0 - _3695) / _3712;\n    }\n    else\n    {\n        float _3766;\n        if (_3712 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3766 = ((-1.0) - _3695) / _3712;\n        }\n        else\n        {\n            _3766 = 1000000015047466219876688855040.0;\n        }\n        _3753 = _3766;\n    }\n    float ty = _3753;\n    float _3782;\n    if (_3716 > 9.9999999747524270787835121154785e-07)\n    {\n        _3782 = (1.0 - _3702) / _3716;\n    }\n    else\n    {\n        float _3795;\n        if (_3716 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3795 = ((-1.0) - _3702) / _3716;\n        }\n        else\n        {\n            _3795 = 1000000015047466219876688855040.0;\n        }\n        _3782 = _3795;\n    }\n    float _3807 = tx;\n    float _3810 = (_3807 > 0.0) ? _3807 : 1000000015047466219876688855040.0;\n    tx = _3810;\n    float _3811 = ty;\n    float _3814 = (_3811 > 0.0) ? _3811 : 1000000015047466219876688855040.0;\n    ty = _3814;\n    float _3824 = min(_3810, min(_3814, (_3782 > 0.0) ? _3782 : 1000000015047466219876688855040.0));\n    if (_3824 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3840 = (fa_world_pos + (d * _3824)) - posw.xyz;\n    vec3 _3845;\n    if (dot(_3840, _3840) > 1.0000000133514319600180897396058e-10)\n    {\n        _3845 = normalize(_3840);\n    }\n    else\n    {\n        _3845 = d;\n    }\n    return _3845;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3891 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3891 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3919 = rough * rough;\n            float _3950 = 0.60000002384185791015625 * _3919;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3919)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3950, 0.0500000007450580596923828125 + _3950, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3919 * 0.60000002384185791015625));\n        }\n        outc = base * _3891;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4009 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4009 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4041 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4041 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4688;\n        if (L.aniso >= 0.0)\n        {\n            _4688 = L.b;\n        }\n        else\n        {\n            _4688 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4688, v), _4688), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4724 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4724.x) + (vec3(L.f90) * _4724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4782 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4782.x) + _4782.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4252 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4252.x) + vec3(_4252.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5492 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5496 = fa_xm_origin(param_1);\n    vec2 _5502 = (uv * _5492) - vec2(0.5);\n    vec2 _5505 = fract(_5502);\n    vec2 _5508 = floor(_5502);\n    vec2 param_2 = _5492;\n    vec2 param_3 = _5496;\n    vec2 param_4 = _5508;\n    vec2 param_5 = _5492;\n    vec2 param_6 = _5496;\n    vec2 param_7 = _5508 + vec2(1.0, 0.0);\n    vec2 param_8 = _5492;\n    vec2 param_9 = _5496;\n    vec2 param_10 = _5508 + vec2(0.0, 1.0);\n    vec2 param_11 = _5492;\n    vec2 param_12 = _5496;\n    vec2 param_13 = _5508 + vec2(1.0);\n    vec3 _5550 = vec3(_5505.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5550), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5550), vec3(_5505.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5569 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5573 = clamp(lod, 0.0, _5569);\n    int _5577 = int(floor(_5573));\n    int param = _5577;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5587 = float(_5577);\n    float _5588 = _5573 - _5587;\n    bool _5590 = _5588 > 0.001000000047497451305389404296875;\n    bool _5597;\n    if (_5590)\n    {\n        _5597 = _5587 < _5569;\n    }\n    else\n    {\n        _5597 = _5590;\n    }\n    if (_5597)\n    {\n        int param_2 = _5577 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5588));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5623 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5623.x) + (vec3(f90) * _5623.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5651 = max(s.thickness, 0.0);\n    bool _5656 = _5651 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5656)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5651);\n    }\n    bool _5681 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5688;\n    if (!_5681)\n    {\n        _5688 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5688 = _5681;\n    }\n    if (_5688)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5656)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5651);\n    }\n    vec4 _5723 = vec4(world, 1.0);\n    float _5728 = dot(fa_mesh_fs_params[28], _5723);\n    vec2 uv = vec2(0.5);\n    if (_5728 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5746 = vec2(dot(fa_mesh_fs_params[26], _5723), dot(fa_mesh_fs_params[27], _5723)) / vec2(_5728);\n        float _5754;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5754 = (_5746.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5754 = 0.5 - (_5746.y * 0.5);\n        }\n        uv = vec2((_5746.x * 0.5) + 0.5, _5754);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3269 = int(fa_shadows[25].x + 0.5);\n    float _3279 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3284 = _3269 > 0;\n    bool _3293;\n    if (_3284)\n    {\n        int param = _3269 - 1;\n        _3293 = _3279 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3293 = _3284;\n    }\n    if (_3293)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3299 = _3269 > 1;\n        bool _3306;\n        if (_3299)\n        {\n            _3306 = _3279 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3306 = _3299;\n        }\n        if (_3306)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3312 = _3269 > 2;\n        bool _3319;\n        if (_3312)\n        {\n            _3319 = _3279 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3319 = _3312;\n        }\n        if (_3319)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3325 = _3269 > 3;\n        bool _3332;\n        if (_3325)\n        {\n            _3332 = _3279 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3332 = _3325;\n        }\n        if (_3332)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8684 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8684 = -_8684;\n    }\n    vec3 _7975 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8684, fa_world_tangent, fa_uv, fa_vertex_color, _7975, gl_FrontFacing);\n    Surface _7983 = fa_standard_surface(param_1);\n    vec3 _8715 = _7983.albedo;\n    float _8716 = _7983.alpha;\n    vec3 _8717 = _7983.normal;\n    float _8718 = _7983.metallic;\n    float _8719 = _7983.roughness;\n    float _8720 = _7983.occlusion;\n    vec3 _8721 = _7983.emission;\n    float _8722 = _7983.clearcoat;\n    float _8723 = _7983.clearcoat_roughness;\n    vec3 _8724 = _7983.sheen_color;\n    float _8725 = _7983.sheen_roughness;\n    float _8726 = _7983.anisotropy;\n    float _8727 = _7983.anisotropy_rotation;\n    float _8728 = _7983.specular;\n    float _8729 = _7983.ior;\n    vec3 _8730 = _7983.specular_color;\n    float _8731 = _7983.transmission;\n    float _8732 = _7983.thickness;\n    vec3 _8733 = _7983.attenuation_color;\n    float _8734 = _7983.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8684, fa_world_tangent, fa_uv, fa_vertex_color, _7975, gl_FrontFacing);\n    Surface param_3 = _7983;\n    surface(param_2, param_3);\n    _8715 = param_3.albedo;\n    _8716 = param_3.alpha;\n    _8717 = param_3.normal;\n    _8718 = param_3.metallic;\n    _8719 = param_3.roughness;\n    _8720 = param_3.occlusion;\n    _8721 = param_3.emission;\n    _8722 = param_3.clearcoat;\n    _8723 = param_3.clearcoat_roughness;\n    _8724 = param_3.sheen_color;\n    _8725 = param_3.sheen_roughness;\n    _8726 = param_3.anisotropy;\n    _8727 = param_3.anisotropy_rotation;\n    _8728 = param_3.specular;\n    _8729 = param_3.ior;\n    _8730 = param_3.specular_color;\n    _8731 = param_3.transmission;\n    _8732 = param_3.thickness;\n    _8733 = param_3.attenuation_color;\n    _8734 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8684;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8715 = param_6;\n    _8717 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8715;\n    }\n    else\n    {\n        vec3 _8023 = normalize(_8717);\n        float _8030 = clamp(_8718, 0.0, 1.0);\n        float _8034 = clamp(_8719, 0.0500000007450580596923828125, 1.0);\n        float _8038 = _8034 * _8034;\n        float _8042 = _8038 * _8038;\n        float _8047 = max(dot(_8023, _7975), 9.9999997473787516355514526367188e-05);\n        float _8053 = 1.0 - _8030;\n        float _8054 = clamp(_8731, 0.0, 1.0) * _8053;\n        vec3 _8063 = (_8715 * _8053) * (1.0 - _8054);\n        vec3 _8070 = mix(vec3(0.039999999105930328369140625), _8715, vec3(_8030));\n        vec3 f0 = _8070;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8684, fa_world_tangent, fa_uv, fa_vertex_color, _7975, gl_FrontFacing);\n        Surface param_9 = Surface(_8715, _8716, _8717, _8718, _8719, _8720, _8721, _8722, _8723, _8724, _8725, _8726, _8727, _8728, _8729, _8730, _8731, _8732, _8733, _8734);\n        vec3 param_10 = _8023;\n        vec3 param_11 = _7975;\n        float param_12 = _8030;\n        float param_13 = _8034;\n        vec3 param_14 = _8070;\n        FaLayers _8086 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8023;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8063) * _8720;\n        if (_8086.on)\n        {\n            lit *= _8086.base_scale;\n        }\n        int _8108 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8108; ln++)\n        {\n            int param_16 = ln;\n            int _8121 = fa_cl_light(param_16);\n            int param_17 = _8121;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8121;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8684;\n            LightSample _8137 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8145 = max(dot(_8023, _8137.direction), 0.0);\n            float _8151 = _8137.attenuation * _8137.shadow;\n            vec3 _8156 = normalize(_8137.direction + _7975);\n            float _8161 = max(dot(_8023, _8156), 0.0);\n            float _8166 = max(dot(_7975, _8156), 0.0);\n            bool _8173;\n            if (fa_light_is_area)\n            {\n                _8173 = !_8086.on;\n            }\n            else\n            {\n                _8173 = fa_light_is_area;\n            }\n            if (_8173)\n            {\n                int param_21 = _8121;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8023;\n                vec3 param_24 = _7975;\n                vec3 param_25 = _8063;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _8034;\n                float param_29 = _8047;\n                float param_30 = _8151;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8086;\n                    int param_32 = _8121;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _8023;\n                    vec3 param_35 = _7975;\n                    vec3 param_36 = _8137.direction;\n                    vec3 param_37 = _8063;\n                    vec3 param_38 = f0;\n                    float param_39 = _8034;\n                    float param_40 = _8047;\n                    float param_41 = _8151;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8086.on)\n                    {\n                        FaLayers param_42 = _8086;\n                        vec3 param_43 = _8063;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _8023;\n                        vec3 param_46 = _7975;\n                        vec3 param_47 = _8137.direction;\n                        vec3 param_48 = _8156;\n                        float param_49 = _8145;\n                        float param_50 = _8047;\n                        float param_51 = _8161;\n                        float param_52 = _8166;\n                        float param_53 = _8038;\n                        float param_54 = _8042;\n                        int param_55 = _8121;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8151));\n                    }\n                    else\n                    {\n                        float _8279 = ((_8161 * _8161) * (_8042 - 1.0)) + 1.0;\n                        int param_56 = _8121;\n                        lit += (((_8063 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8166, 5.0))) * (((_8042 / ((3.1415927410125732421875 * _8279) * _8279)) * (0.5 / max(mix((2.0 * _8145) * _8047, _8145 + _8047, _8038), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8145))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8145 * _8151));\n                    }\n                }\n            }\n        }\n        if (_8086.on)\n        {\n            FaLayers param_57 = _8086;\n            vec3 param_58 = _8023;\n            vec3 param_59 = _7975;\n            vec3 param_60 = f0;\n            float param_61 = _8034;\n            float param_62 = _8720;\n            lit += fa_layers_ibl(param_57, param_58, param_59, param_60, param_61, param_62);\n        }\n        else\n        {\n            vec3 param_63 = _8023;\n            vec3 param_64 = _7975;\n            vec3 param_65 = f0;\n            float param_66 = _8034;\n            lit += (fa_sky_reflection(param_63, param_64, param_65, param_66) * _8720);\n        }\n        if (_8054 > 0.0)\n        {\n            float _8377;\n            if (_8086.on)\n            {\n                _8377 = _8086.f90;\n            }\n            else\n            {\n                _8377 = 1.0;\n            }\n            float _8385;\n            if (_8086.on)\n            {\n                _8385 = _8086.base_scale;\n            }\n            else\n            {\n                _8385 = 1.0;\n            }\n            Surface param_67 = Surface(_8715, _8716, _8717, _8718, _8719, _8720, _8721, _8722, _8723, _8724, _8725, _8726, _8727, _8728, _8729, _8730, _8731, _8732, _8733, _8734);\n            vec3 param_68 = _8023;\n            vec3 param_69 = _7975;\n            float param_70 = _8034;\n            vec3 param_71 = f0;\n            float param_72 = _8377;\n            float param_73 = _8385;\n            float param_74 = _8054;\n            float param_75 = fa_tr_blend;\n            vec3 _8409 = fa_transmitted(param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74, param_75);\n            fa_tr_blend = param_75;\n            lit += _8409;\n        }\n        result = lit;\n    }\n    vec3 _8416 = result;\n    vec3 _8417 = _8416 + _8721;\n    result = _8417;\n    vec3 param_76 = _8417;\n    vec3 param_77 = fa_world_pos;\n    result = fa_shadow_debug(param_76, param_77);\n    bool _8426 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8433;\n    if (!_8426)\n    {\n        _8433 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8433 = _8426;\n    }\n    if (_8433)\n    {\n        vec3 _8442 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8448 = dot(_8442, fa_mesh_fs_params[9].xyz);\n        bool _8452 = fa_mesh_fs_params[9].w > 0.5;\n        float _8453;\n        if (_8452)\n        {\n            _8453 = _8448;\n        }\n        else\n        {\n            _8453 = length(_8442);\n        }\n        float _8465 = _8453 - fa_mesh_fs_params[8].x;\n        if (_8465 > 0.0)\n        {\n            float _8474 = fa_mesh_fs_params[7].w * _8465;\n            float tau = _8474 * _8474;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8490;\n                if (_8452)\n                {\n                    _8490 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8448);\n                }\n                else\n                {\n                    _8490 = fa_mesh_fs_params[0].y;\n                }\n                float _8511 = mix(_8490, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8453, 0.0, 1.0));\n                float _8515 = fa_world_pos.y - _8511;\n                float _8520 = _8511 - fa_mesh_fs_params[8].z;\n                float _8525 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8528 = _8520 <= 0.0;\n                bool _8529 = !_8528;\n                bool _8535;\n                if (_8529)\n                {\n                    _8535 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8535 = _8528;\n                }\n                float _8536;\n                if (_8535)\n                {\n                    _8536 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8536 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8520, 80.0));\n                }\n                bool _8563;\n                if (_8529)\n                {\n                    _8563 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8563 = _8528;\n                }\n                float _8564;\n                if (_8563)\n                {\n                    _8564 = fa_mesh_fs_params[8].y * _8520;\n                }\n                else\n                {\n                    _8564 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8520, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8589 = _8525 <= 0.0;\n                bool _8596;\n                if (!_8589)\n                {\n                    _8596 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8596 = _8589;\n                }\n                float _8597;\n                if (_8596)\n                {\n                    _8597 = fa_mesh_fs_params[8].y * _8525;\n                }\n                else\n                {\n                    _8597 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8525, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8624;\n                if (abs(_8515) < 0.001000000047497451305389404296875)\n                {\n                    _8624 = _8536;\n                }\n                else\n                {\n                    _8624 = (_8597 - _8564) / _8515;\n                }\n                tau += (_8465 * max(_8624, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8660 = 1.0 - fa_tr_blend;\n        result /= vec3(_8660);\n        _8716 *= _8660;\n    }\n    fa_frag_color = vec4(result, _8716);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
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
            "inst_name": "_653",
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
            "inst_name": "_2315",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_188 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_188 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_188 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4353[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1591 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1598;\n    if (!_1591)\n    {\n        _1598 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1598 = _1591;\n    }\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    bool _1613;\n    if (!_1606)\n    {\n        _1613 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1613 = _1606;\n    }\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    if (_1620)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1630 = vec4(world_pos, 1.0);\n    float _1636 = dot(fa_mesh_fs_params[16], _1630);\n    if (!(_1636 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1658 = vec2(dot(fa_mesh_fs_params[14], _1630), dot(fa_mesh_fs_params[15], _1630)) / vec2(_1636);\n    int _1662 = int(fa_mesh_fs_params[18].x);\n    int _1666 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1666) + clamp(int(floor(((_1658.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1666 - 1)) * _1662)) + clamp(int(floor(((_1658.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1662 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1742 = fa_cluster_texel(param);\n    return ivec2(int(_1742.x), int(_1742.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5828 = fa_cluster_lookup(param);\n    fa_cl_slot = _5828.x;\n    fa_cl_local = _5828.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6961 = fa_linear_to_srgb(param);\n        c = _6961;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6969 = fa_srgb_to_linear(param_1);\n            c = _6969;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _535;\n    if (i.front_facing)\n    {\n        _535 = i.world_normal;\n    }\n    else\n    {\n        _535 = -i.world_normal;\n    }\n    vec3 _559 = normalize(i.world_tangent.xyz - (_535 * dot(_535, i.world_tangent.xyz)));\n    vec3 _586 = normalize(((_559 * m.x) + ((cross(_535, _559) * i.world_tangent.w) * m.y)) + (_535 * m.z));\n    vec3 _589;\n    if (i.front_facing)\n    {\n        _589 = _586;\n    }\n    else\n    {\n        _589 = -_586;\n    }\n    return _589;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7000 = fa_tex_fix(param_2, param_3);\n    vec4 _9261 = base_t;\n    _9261.x = _7000.x;\n    _9261.y = _7000.y;\n    _9261.z = _7000.z;\n    base_t = _9261;\n    vec4 _7014 = (_9261 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9045 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7046 = fa_tex_fix(param_6, param_7);\n        vec3 _7049 = (_7046 * 2.0) - vec3(1.0);\n        vec2 _7054 = _7049.xy * fa_mesh_fs_params[6].x;\n        vec3 _9269 = _7049;\n        _9269.x = _7054.x;\n        _9269.y = _7054.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9269;\n        _9045 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7082 = fa_tex_fix(param_12, param_13);\n    vec4 _9272 = mrt;\n    _9272.x = _7082.x;\n    _9272.y = _7082.y;\n    _9272.z = _7082.z;\n    mrt = _9272;\n    vec4 _7110 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7110.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7121 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7151 = fa_tex_fix(param_20, param_21);\n    float _9050 = fa_mesh_fs_params[20].x;\n    float _9051 = fa_mesh_fs_params[20].y;\n    float _9054 = fa_mesh_fs_params[20].z;\n    float _9053 = fa_mesh_fs_params[21].w;\n    float _9056 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9050 *= _7121.y;\n            _9051 *= _7121.z;\n            _9053 *= _7110.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9054 *= mrt.x;\n            _9056 *= mrt.w;\n        }\n    }\n    return Surface(_7014.xyz, _7014.w, _9045, clamp(fa_mesh_fs_params[5].x * _7082.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7082.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7121.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7151), _9050, _9051, fa_mesh_fs_params[21].xyz, _9053, _9054, fa_mesh_fs_params[20].w, _9056, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1822 = rect.zw - rect.xy;\n    vec2 _1826 = _1822 * atlas;\n    vec2 _1830 = ddx * _1826;\n    vec2 _1834 = ddy * _1826;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1822), clamp(0.5 * log2(max(max(dot(_1830, _1830), dot(_1834, _1834)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1867 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1874;\n    if (!_1867)\n    {\n        _1874 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1874 = _1867;\n    }\n    if (_1874)\n    {\n        return;\n    }\n    vec3 _1880 = dFdx(world_pos);\n    vec3 _1883 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1887 = fa_cluster_texel(param);\n    int _1891 = int(_1887.w);\n    if (_1891 < 1)\n    {\n        return;\n    }\n    int _1901 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1901;\n    vec4 _1905 = fa_light_texel(param_1);\n    vec2 _1908 = _1905.yz;\n    int _1912 = int(_1905.w);\n    int param_2 = _1901 + 1;\n    vec4 _1917 = fa_light_texel(param_2);\n    float _1918 = _1917.x;\n    int _1924 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1928 = int(_1887.z);\n    vec3 _2193;\n    for (int k = 0; k < _1891; k++)\n    {\n        int _1941 = _1928 + k;\n        int param_3 = _1912 + (_1941 >> 2);\n        int _1958 = (_1901 + 2) + (int(fa_light_texel(param_3)[_1941 & 3]) * 7);\n        int param_4 = _1958 + 6;\n        vec4 _1963 = fa_light_texel(param_4);\n        if (((int(_1963.w + 0.5) >> _1924) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1958;\n        vec4 _1978 = fa_light_texel(param_5);\n        int param_6 = _1958 + 1;\n        vec4 _1983 = fa_light_texel(param_6);\n        int param_7 = _1958 + 2;\n        vec4 _1988 = fa_light_texel(param_7);\n        vec3 _1991 = _1978.xyz;\n        float _1996 = dot(_1991, world_pos) + _1978.w;\n        vec3 _1998 = _1983.xyz;\n        float _2003 = dot(_1998, world_pos) + _1983.w;\n        vec3 _2005 = _1988.xyz;\n        float _2010 = dot(_2005, world_pos) + _1988.w;\n        bool _2015 = abs(_1996) > 0.5;\n        bool _2023;\n        if (!_2015)\n        {\n            _2023 = abs(_2003) > 0.5;\n        }\n        else\n        {\n            _2023 = _2015;\n        }\n        bool _2031;\n        if (!_2023)\n        {\n            _2031 = abs(_2010) > 0.5;\n        }\n        else\n        {\n            _2031 = _2023;\n        }\n        if (_2031)\n        {\n            continue;\n        }\n        float _2046 = clamp(dot(geo_normal, normalize(_2005)) * _1963.z, 0.0, 1.0);\n        if (_2046 <= 0.0)\n        {\n            continue;\n        }\n        float _2066 = (clamp((0.5 - abs(_2010)) * 10.0, 0.0, 1.0) * _2046) * _1963.x;\n        vec2 _2074 = vec2(_1996 + 0.5, 0.5 - _2003);\n        vec2 _2084 = vec2(dot(_1991, _1880), dot(_1998, _1880));\n        vec2 _2094 = vec2(dot(_1991, _1883), dot(_1998, _1883));\n        int param_8 = _1958 + 5;\n        vec4 _2099 = fa_light_texel(param_8);\n        int param_9 = _1958 + 3;\n        vec4 _2104 = fa_light_texel(param_9);\n        int param_10 = _1958 + 4;\n        vec4 _2109 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2099.xyz;\n        bool _2119 = _2104.z > _2104.x;\n        if (_2119)\n        {\n            vec4 param_11 = _2104;\n            vec2 param_12 = _2074;\n            vec2 param_13 = _1908;\n            vec2 param_14 = _2084;\n            vec2 param_15 = _2094;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1918 > 0.5) && (_1918 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2145 = fa_dc_to_linear(param_16);\n                vec4 _9133 = tx;\n                _9133.x = _2145.x;\n                _9133.y = _2145.y;\n                _9133.z = _2145.z;\n                tx = _9133;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2066 * tex_a) * _2099.w, 0.0, 1.0)));\n        if (_2109.z > _2109.x)\n        {\n            vec4 param_17 = _2109;\n            vec2 param_18 = _2074;\n            vec2 param_19 = _1908;\n            vec2 param_20 = _2084;\n            vec2 param_21 = _2094;\n            vec4 _2189 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1918 > 1.5)\n            {\n                vec3 param_22 = _2189.xyz;\n                vec3 _2199 = fa_dc_to_srgb(param_22);\n                _2193 = _2199;\n            }\n            else\n            {\n                _2193 = _2189.xyz;\n            }\n            vec3 _2208 = (_2193 * 2.0) - vec3(1.0);\n            vec2 _2213 = _2208.xy * _1963.y;\n            vec3 _2235 = (normalize(_1991) * _2213.x) + (normalize(_1998) * _2213.y);\n            vec3 _2238 = normalize(normal);\n            normal = normalize(mix(_2238, normalize((_2238 * max(_2208.z, 0.0500000007450580596923828125)) + (_2235 - (_2238 * dot(_2238, _2235)))), vec3(clamp(_2066 * (_2119 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4278 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4286 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4289 = int(_4278);\n    int _4292 = int(_4286);\n    float _4302 = _4286 - float(_4292);\n    int _4357 = (_4289 * 9) + _4292;\n    int _4377 = ((_4289 + 1) * 9) + _4292;\n    return mix(mix(_4353[_4357], _4353[_4357 + 1], _4302), mix(_4353[_4377], _4353[_4377 + 1], _4302), _4278 - float(_4289));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _8968 = false;\n    float _8969 = 1.0;\n    float _8970 = 1.0;\n    float _8971 = 1.0;\n    float _8972 = 0.0;\n    float _8973 = 0.0;\n    float _8974 = 0.0;\n    float _8975 = 0.0;\n    float _8977 = 1.0;\n    bool _8978 = false;\n    vec3 _8979 = vec3(0.0);\n    float _8980 = 1.0;\n    float _8981 = 1.0;\n    float _8982 = 1.0;\n    float _8983 = 0.0;\n    float _8984 = 0.0;\n    vec3 _8985 = vec3(1.0, 0.0, 0.0);\n    vec3 _8986 = vec3(0.0, 0.0, 1.0);\n    float _8987 = 1.0;\n    float _8988 = 1.0;\n    float _4428 = clamp(s.specular, 0.0, 1.0);\n    float _4432 = clamp(s.ior, 1.0, 3.0);\n    bool _4437 = (_4428 != 1.0) || (_4432 != 1.5);\n    bool _4446;\n    if (!_4437)\n    {\n        _4446 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4446 = _4437;\n    }\n    if (_4446)\n    {\n        float _4454 = (_4432 - 1.0) / (_4432 + 1.0);\n        f0 = mix(min(vec3(_4454 * _4454) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4428, s.albedo, vec3(metallic));\n        _8969 = mix(_4428, 1.0, metallic);\n        _8968 = true;\n    }\n    float _4481 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4481 > 0.0)\n    {\n        float _4489 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _8972 = _4481;\n        _8973 = _4489;\n        float _4496 = _4489 * _4489;\n        _8974 = _4496;\n        _8975 = _4496 * _4496;\n        float _4508 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _8977 = _4508;\n        _8970 = 1.0 - (_4481 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4508, 0.0, 1.0), 5.0))));\n        _8968 = true;\n    }\n    vec3 _4527 = max(s.sheen_color, vec3(0.0));\n    float _4536 = max(_4527.x, max(_4527.y, _4527.z));\n    if (_4536 > 0.0)\n    {\n        float _4544 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _8978 = true;\n        _8979 = _4527;\n        _8980 = _4544;\n        _8981 = _4544 * _4544;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4544;\n        float _4561 = fa_sheen_albedo(param, param_1);\n        _8983 = _4561;\n        _8982 = 1.0 - min(_4536 * _4561, 1.0);\n        _8968 = true;\n    }\n    _8971 = _8970 * _8982;\n    float _4580 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4580 != 0.0)\n    {\n        vec3 _4595 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4595;\n        if (dot(_4595, _4595) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4607 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4607.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4607.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4607.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4611 = t;\n        vec3 _4612 = normalize(_4611);\n        t = _4612;\n        vec3 _4637 = normalize((_4612 * cos(s.anisotropy_rotation)) + ((cross(n, _4612) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _8985 = _4637;\n        _8986 = cross(n, _4637);\n        float _4647 = roughness * roughness;\n        float _4653 = mix(_4647, 1.0, _4580 * _4580);\n        bool _4655 = _4580 > 0.0;\n        _8987 = _4655 ? _4653 : _4647;\n        _8988 = _4655 ? _4647 : _4653;\n        _8984 = _4580;\n        _8968 = true;\n    }\n    return FaLayers(_8968, _8969, _8970, _8971, _8972, _8973, _8974, _8975, i.world_normal, _8977, _8978, _8979, _8980, _8981, _8982, _8983, _8984, _8985, _8986, _8987, _8988);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3446 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3446;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4059 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4064 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4059 > 0.0005000000237487256526947021484375)\n    {\n        if (_4064)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4059;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4059;\n        }\n    }\n    bool _4115 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4115)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4146 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4146)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4064 || _4115) || _4146)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3466 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3469 = _3466.x;\n    float _3471 = _3466.z;\n    vec2 e = vec2(_3469, _3471);\n    if (_3466.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3471)) * ((_3469 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3469)) * ((_3471 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7261 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7266 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7271 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7276 = fa_light_texel(param_3);\n    bool _7279 = _7276.z < 0.5;\n    bool _7287;\n    if (!_7279)\n    {\n        _7287 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7287 = _7279;\n    }\n    if (_7287)\n    {\n        return vec3(0.0);\n    }\n    float _7294 = max(_7261.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7297 = _7266.xyz;\n    vec3 _7301 = _7261.xyz;\n    vec3 _7305 = (fa_world_pos - _7301) / vec3(_7294);\n    vec3 _7314 = min(_7305 + vec3(0.5), (_7297 - vec3(0.5)) - _7305);\n    float _7323 = min(_7314.x, min(_7314.y, _7314.z));\n    if (!(_7323 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7338 = _7297 - vec3(1.0);\n    vec3 _7339 = clamp(_7305, vec3(0.0), _7338);\n    vec3 _7347 = min(floor(_7339), max(_7297 - vec3(2.0), vec3(0.0)));\n    vec3 _7351 = _7339 - _7347;\n    vec3 _7362 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7294));\n    int _7367 = int(_7271.y + 0.5);\n    float _7372 = 0.3257350027561187744140625 * n.y;\n    float _7376 = 0.3257350027561187744140625 * n.z;\n    float _7380 = 0.3257350027561187744140625 * n.x;\n    float _7387 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7394 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7403 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7410 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7423 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7430 = 8 + int(_7276.w);\n    float _7457;\n    float _7470;\n    float _7484;\n    for (int k = 0; k < _7430; k++)\n    {\n        float _7443 = float(k & 1);\n        float _7447 = float((k >> 1) & 1);\n        float _7451 = float((k >> 2) & 1);\n        if (_7443 > 0.5)\n        {\n            _7457 = _7351.x;\n        }\n        else\n        {\n            _7457 = 1.0 - _7351.x;\n        }\n        if (_7447 > 0.5)\n        {\n            _7470 = _7351.y;\n        }\n        else\n        {\n            _7470 = 1.0 - _7351.y;\n        }\n        if (_7451 > 0.5)\n        {\n            _7484 = _7351.z;\n        }\n        else\n        {\n            _7484 = 1.0 - _7351.z;\n        }\n        float _7494 = (_7457 * _7470) * _7484;\n        if (!(_7494 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7507 = min(_7347 + vec3(_7443, _7447, _7451), _7338);\n        int _7527 = int(((_7271.x + _7507.x) + (_7266.x * (_7507.y + (_7266.y * _7507.z)))) + 0.5);\n        vec2 _7542 = vec2(float(_7527 % _7367) * 10.0, 1024.0 + (float(_7527 / _7367) * 11.0));\n        vec2 param_4 = _7542 + vec2(9.5, 10.5);\n        vec4 _7550 = fa_gi_fetch(param_4);\n        bool _7553 = _7550.y < 0.5;\n        bool _7562;\n        if (!_7553)\n        {\n            _7562 = _7550.x > _7276.y;\n        }\n        else\n        {\n            _7562 = _7553;\n        }\n        if (_7562)\n        {\n            continue;\n        }\n        vec3 _7574 = _7362 - (_7301 + (_7507 * _7294));\n        float _7577 = length(_7574);\n        vec3 _7583 = _7574 / vec3(max(_7577, 9.9999997473787516355514526367188e-05));\n        float _7593 = max(9.9999997473787516355514526367188e-05, (dot(-_7583, n) + 1.0) * 0.5);\n        float w = _7494 * (_7593 * _7593);\n        vec3 param_5 = _7583;\n        vec2 param_6 = (_7542 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7612 = fa_gi_fetch(param_6);\n        float _7619 = _7577 / max(_7271.z, 9.9999997473787516355514526367188e-05);\n        float _7622 = _7612.x;\n        if (_7619 > _7622)\n        {\n            float _7635 = max(_7612.y - (_7622 * _7622), 0.0);\n            float _7640 = _7619 - _7622;\n            float _7649 = _7635 / max(_7635 + (_7640 * _7640), 9.9999999600419720025001879548654e-13);\n            w *= ((_7649 * _7649) * _7649);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7542 + vec2(0.5, 10.5);\n        vec2 param_8 = _7542 + vec2(1.5, 10.5);\n        vec2 param_9 = _7542 + vec2(2.5, 10.5);\n        vec2 param_10 = _7542 + vec2(3.5, 10.5);\n        vec2 param_11 = _7542 + vec2(4.5, 10.5);\n        vec2 param_12 = _7542 + vec2(5.5, 10.5);\n        vec2 param_13 = _7542 + vec2(6.5, 10.5);\n        vec2 param_14 = _7542 + vec2(7.5, 10.5);\n        vec2 param_15 = _7542 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7372)) + (fa_gi_fetch(param_9).xyz * _7376)) + (fa_gi_fetch(param_10).xyz * _7380)) + (fa_gi_fetch(param_11).xyz * _7387)) + (fa_gi_fetch(param_12).xyz * _7394)) + (fa_gi_fetch(param_13).xyz * _7403)) + (fa_gi_fetch(param_14).xyz * _7410)) + (fa_gi_fetch(param_15).xyz * _7423)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7323 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7774;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7774 = _7276.x;\n    }\n    else\n    {\n        _7774 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7271.w * _7774);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7798 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7803 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7808 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7808) && (k < 8); k++)\n    {\n        int param = _7803 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7798;\n        vec3 _7833 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7838 = param_3 * left;\n        acc += (_7833 * _7838);\n        left -= _7838;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7867 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7867;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5798;\n    if (fa_lm.z > 0.5)\n    {\n        _5798 = 0.0;\n    }\n    else\n    {\n        _5798 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5809 = _5798 < 1.0;\n    bool _5815;\n    if (_5809)\n    {\n        int param = li;\n        _5815 = fa_light_baked(param);\n    }\n    else\n    {\n        _5815 = _5809;\n    }\n    return _5815 ? _5798 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _840 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _853 = (c - (ru * hx)) - p;\n        vec3 _859 = ru * (2.0 * hx);\n        float _865 = max(dot(_859, _859), 9.9999999392252902907785028219223e-09);\n        float _869 = dot(_853, _859);\n        float t = clamp((-_869) / _865, 0.0, 1.0);\n        if (_840)\n        {\n            float _884 = dot(r, _859);\n            float _890 = _865 - (_884 * _884);\n            if (abs(_890) > (9.9999997473787516355514526367188e-06 * _865))\n            {\n                t = clamp(((dot(r, _853) * _884) - _869) / _890, 0.0, 1.0);\n            }\n        }\n        return (p + _853) + (_859 * t);\n    }\n    vec3 q = p;\n    float _922 = dot(r, axis);\n    bool _930;\n    if (_840)\n    {\n        _930 = abs(_922) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _930 = _840;\n    }\n    if (_930)\n    {\n        float _940 = dot(c - p, axis) / _922;\n        if (_940 > 0.0)\n        {\n            q = p + (r * _940);\n        }\n    }\n    vec3 _953 = q - c;\n    vec2 xy = vec2(dot(_953, ru), dot(_953, uu));\n    if (shape > 0.5)\n    {\n        float _968 = length(xy);\n        if (_968 > hx)\n        {\n            xy *= (hx / _968);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _601 = abs(d);\n    float _603 = _601.x;\n    float _605 = _601.y;\n    bool _606 = _603 >= _605;\n    bool _614;\n    if (_606)\n    {\n        _614 = _603 >= _601.z;\n    }\n    else\n    {\n        _614 = _606;\n    }\n    int _615;\n    if (_614)\n    {\n        _615 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _630;\n        if (_605 >= _601.z)\n        {\n            _630 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _630 = (d.z > 0.0) ? 4 : 5;\n        }\n        _615 = _630;\n    }\n    return _615;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _760 = dot(d, right);\n    float _764 = dot(d, up);\n    float _775;\n    if (((_760 * _760) + (_764 * _764)) > 1.0000000133514319600180897396058e-10)\n    {\n        _775 = atan(_764, _760) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _775 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_775 - floor(_775)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1006 = fa_light_base(param);\n    bool _1010 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1006;\n    vec4 _1014 = fa_light_texel(param_1);\n    int param_2 = _1006 + 1;\n    vec4 _1019 = fa_light_texel(param_2);\n    float _1022 = _1019.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1034 = _1010 && (_1022 > 2.5);\n    fa_light_is_area = _1034;\n    bool _1036 = _1022 < 0.5;\n    vec3 l;\n    if (_1036)\n    {\n        l = normalize(_1014.xyz);\n        if (_1010)\n        {\n            int param_3 = _1006 + 6;\n            vec4 _1050 = fa_light_texel(param_3);\n            if (_1050.z > 0.5)\n            {\n                int param_4 = _1006 + 4;\n                vec4 _1060 = fa_light_texel(param_4);\n                int param_5 = _1006 + 5;\n                vec4 _1065 = fa_light_texel(param_5);\n                vec2 param_6 = _1050.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1060.xyz) * _1060.w, (-dot(world_pos, _1065.xyz)) * _1065.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1095 = _1014.xyz;\n        vec3 _1097 = _1095 - world_pos;\n        vec3 to_light = _1097;\n        float _1100 = length(_1097);\n        float reach = _1100;\n        bool front = true;\n        if (_1034)\n        {\n            int param_8 = _1006 + 7;\n            reach = max(_1100 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1006 + 4;\n            vec4 _1124 = fa_light_texel(param_9);\n            int param_10 = _1006 + 5;\n            vec4 _1129 = fa_light_texel(param_10);\n            int param_11 = _1006 + 6;\n            vec4 _1134 = fa_light_texel(param_11);\n            float _1135 = _1134.w;\n            int param_12 = _1006 + 2;\n            vec3 _1142 = normalize(fa_light_texel(param_12).xyz);\n            bool _1144 = _1135 > 1.5;\n            bool _1152;\n            if (!_1144)\n            {\n                _1152 = dot(_1142, to_light) < 0.0;\n            }\n            else\n            {\n                _1152 = _1144;\n            }\n            front = _1152;\n            vec3 r = vec3(0.0);\n            vec3 _1161 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1165 = dot(n, n) > 0.5;\n            bool _1173;\n            if (_1165)\n            {\n                _1173 = dot(_1161, _1161) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1173 = _1165;\n            }\n            if (_1173)\n            {\n                r = reflect(-normalize(_1161), normalize(n));\n            }\n            vec3 param_13 = _1095;\n            vec3 param_14 = _1142;\n            vec3 param_15 = _1124.xyz;\n            vec3 param_16 = _1129.xyz;\n            float param_17 = _1124.w;\n            float param_18 = _1129.w;\n            float param_19 = _1135;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1209 = length(to_light);\n        dist = _1209;\n        l = to_light / vec3(max(_1209, 9.9999997473787516355514526367188e-05));\n        float _1223 = reach / max(_1014.w, 0.001000000047497451305389404296875);\n        float _1229 = clamp(1.0 - (_1223 * _1223), 0.0, 1.0);\n        float _1231;\n        if (front)\n        {\n            _1231 = _1229 * _1229;\n        }\n        else\n        {\n            _1231 = 0.0;\n        }\n        atten = _1231;\n        bool _1242 = _1022 < 2.5;\n        if ((_1022 > 1.5) && _1242)\n        {\n            int param_22 = _1006 + 2;\n            vec4 _1250 = fa_light_texel(param_22);\n            float _1260 = _1250.w;\n            int param_23 = _1006 + 3;\n            vec4 _1265 = fa_light_texel(param_23);\n            float _1266 = _1265.x;\n            float cos_inner = _1266;\n            if (_1266 > 1.5)\n            {\n                cos_inner = mix(_1260, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1260, cos_inner, dot(-l, normalize(_1250.xyz)));\n        }\n        if (_1010 && (_1022 < 1.5))\n        {\n            int param_24 = _1006 + 6;\n            vec4 _1290 = fa_light_texel(param_24);\n            if (_1290.z > 0.5)\n            {\n                vec3 _1298 = -to_light;\n                int param_25 = _1006 + 4;\n                int param_26 = _1006 + 5;\n                vec3 _1312 = fa_light_texel(param_25).xyz;\n                vec3 _1316 = fa_light_texel(param_26).xyz;\n                vec3 _1325 = vec3(dot(_1298, _1312), dot(_1298, _1316), dot(_1298, cross(_1312, _1316)));\n                vec3 param_27 = _1325;\n                int _1329 = fa_cube_face(param_27);\n                int param_28 = _1329;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1356 = vec2(dot(_1325, cross(param_29, param_30)), dot(_1325, param_30)) / vec2(max(dot(_1325, param_29), 9.9999997473787516355514526367188e-05));\n                int _1360 = _1329 / 3;\n                vec2 param_31 = _1290.xy + (vec2(float(_1329 - (_1360 * 3)), float(_1360)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1356.x), 0.5 - (0.5 * _1356.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1006 + 7;\n            vec4 _1390 = fa_light_texel(param_33);\n            if (_1390.z > 0.5)\n            {\n                int param_34 = _1006 + 2;\n                int param_35 = _1006 + 4;\n                int param_36 = _1006 + 5;\n                vec2 param_37 = _1390.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1010 && _1242)\n            {\n                int param_42 = _1006 + 6;\n                vec4 _1437 = fa_light_texel(param_42);\n                int param_43 = _1006 + 7;\n                vec4 _1442 = fa_light_texel(param_43);\n                bool _1445 = _1437.z > 0.5;\n                bool _1452;\n                if (!_1445)\n                {\n                    _1452 = _1442.z > 0.5;\n                }\n                else\n                {\n                    _1452 = _1445;\n                }\n                if (_1452)\n                {\n                    int param_44 = _1006 + 2;\n                    vec4 _1459 = fa_light_texel(param_44);\n                    vec3 _1463 = normalize(_1459.xyz);\n                    int param_45 = _1006 + 4;\n                    vec4 _1468 = fa_light_texel(param_45);\n                    int param_46 = _1006 + 5;\n                    vec4 _1473 = fa_light_texel(param_46);\n                    if (_1445)\n                    {\n                        vec3 _1481 = -to_light;\n                        float _1488 = _1459.w;\n                        float _1504 = 0.5 / max(dot(_1481, _1463) * (sqrt(max(1.0 - (_1488 * _1488), 0.0)) / max(_1488, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1437.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1481, _1468.xyz) * _1504), 0.5 - (dot(_1481, _1473.xyz) * _1504));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1442.z > 0.5)\n                    {\n                        vec2 param_49 = _1442.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1463;\n                        vec3 param_52 = _1468.xyz;\n                        vec3 param_53 = _1473.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8956 = _1019.xyz * atten;\n    if (_1010)\n    {\n        _8956 *= fa_light_tint;\n    }\n    int _1573;\n    if (_1036)\n    {\n        _1573 = 0;\n    }\n    else\n    {\n        _1573 = ((_1022 > 1.5) && (_1022 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8956, atten, 1.0, dist, _1573);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2305;\n    if (i == 0)\n    {\n        _2305 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2321;\n        if (i == 1)\n        {\n            _2321 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2329;\n            if (i == 2)\n            {\n                _2329 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2329 = fa_shadows[24].w;\n            }\n            _2321 = _2329;\n        }\n        _2305 = _2321;\n    }\n    return _2305;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2362 = fa_shadow_depth(param, param_1);\n    float _2366;\n    if (conv.x < 0.5)\n    {\n        _2366 = _2362;\n    }\n    else\n    {\n        _2366 = (conv.y * conv.z) / (conv.z - (_2362 * (conv.z - conv.y)));\n    }\n    return _2366;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2412 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2418 = vec2(cos(_2412), sin(_2412));\n    vec2 dir = _2418;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2427;\n        if (k < 0.0)\n        {\n            _2427 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2427 = k;\n        }\n        float _2446 = clamp((_2427 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2465 = sqrt((float(i) + 0.5) * 0.0625) * _2446;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2465));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2479 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2479 < (zr - (_2465 * plane)))\n            {\n                sum += _2479;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2507 = sum / cnt;\n        float _2517;\n        if (k < 0.0)\n        {\n            _2517 = (-k) / max(_2507, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2517 = k;\n        }\n        radius = clamp(((max(zr - _2507, 0.0) * unit) * _2517) / texel_m, 1.5, 16.0);\n        dir = _2418;\n    }\n    float lit = 0.0;\n    int _2543 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2543; i_1++)\n    {\n        float _2562 = sqrt((float(i_1) + 0.5) / float(_2543)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2562));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2562 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2543);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2608 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2613 = clamp(dot(n, l), 0.0, 1.0);\n    float _2619 = sqrt(1.0 - (_2613 * _2613));\n    float _2627 = min(_2619 / max(_2613, 0.20000000298023223876953125), 4.0);\n    float _2632;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2632 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2632 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2657 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2632 * _2619)), 1.0);\n    float _2664 = _2657.x;\n    bool _2667 = _2664 < fa_shadows[ci * 1 + 16].x;\n    bool _2676;\n    if (!_2667)\n    {\n        _2676 = _2664 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2676 = _2667;\n    }\n    bool _2685;\n    if (!_2676)\n    {\n        _2685 = _2657.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2685 = _2676;\n    }\n    bool _2694;\n    if (!_2685)\n    {\n        _2694 = _2657.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2694 = _2685;\n    }\n    bool _2701;\n    if (!_2694)\n    {\n        _2701 = _2657.z > 1.0;\n    }\n    else\n    {\n        _2701 = _2694;\n    }\n    if (_2701)\n    {\n        return -1.0;\n    }\n    float _2709;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2709 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2709 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2657.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2657.z - ((_2709 * (1.0 + (0.5 * _2627))) / _2608);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2608;\n    float param_5 = _2608 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2627, 3.0)) * 0.5) / _2608;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3087 = int(fa_shadows[25].x + 0.5);\n    if (_3087 < 1)\n    {\n        return 1.0;\n    }\n    float _3102 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3087 - 1;\n    if (_3102 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3114 = _3087 > 1;\n    bool _3121;\n    if (_3114)\n    {\n        _3121 = _3102 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3121 = _3114;\n    }\n    if (_3121)\n    {\n        ci = 1;\n    }\n    bool _3125 = _3087 > 2;\n    bool _3132;\n    if (_3125)\n    {\n        _3132 = _3102 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3132 = _3125;\n    }\n    if (_3132)\n    {\n        ci = 2;\n    }\n    bool _3136 = _3087 > 3;\n    bool _3143;\n    if (_3136)\n    {\n        _3143 = _3102 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3143 = _3136;\n    }\n    if (_3143)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3087)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3169 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3169;\n        if (_3169 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3194;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3194 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3194 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3213 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3194, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3224 = clamp((_3102 - (fa_shadow_split_at(param_7) - _3213)) / _3213, 0.0, 1.0);\n        if (_3224 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3087)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3245 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3245;\n                if (_3245 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3224);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2767 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2774;\n    if (!_2767)\n    {\n        _2774 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2774 = _2767;\n    }\n    if (_2774)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2787 = fa_light_texel(param);\n    float _2788 = _2787.x;\n    if (_2788 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2797 = int(_2788 + 0.5);\n    int param_1 = _2797;\n    vec4 _2801 = fa_light_texel(param_1);\n    int param_2 = _2797 + 1;\n    vec4 _2806 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2809 = _2801.y;\n    if (_2809 > 0.0)\n    {\n        float _2826 = 1.0 - smoothstep(0.75 * _2809, _2809, length(world - fa_shadows[27].xyz));\n        fade = _2826;\n        if (_2826 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2801.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2850 = (_2797 + 2) + (face * 6);\n    int param_4 = _2850;\n    int param_5 = _2850 + 1;\n    int param_6 = _2850 + 3;\n    vec4 _2864 = fa_light_texel(param_6);\n    int param_7 = _2850 + 4;\n    vec4 _2869 = fa_light_texel(param_7);\n    int param_8 = _2850 + 5;\n    vec4 _2874 = fa_light_texel(param_8);\n    float _2886 = _2874.x * max(dot(_2864, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2891 = clamp(dot(n, l), 0.0, 1.0);\n    float _2914 = clamp(dot(n, _2864.xyz), -1.0, 1.0);\n    float _2933 = min(sqrt(1.0 - (_2914 * _2914)) / max(abs(dot(n, world - lpos)) / max(dot(_2864, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2936 = _2806.y;\n    float _2938;\n    if (_2936 > 0.0)\n    {\n        _2938 = _2936;\n    }\n    else\n    {\n        _2938 = 1.5 * _2886;\n    }\n    vec4 _2958 = vec4(world + (n * (_2938 * sqrt(1.0 - (_2891 * _2891)))), 1.0);\n    float _2962 = dot(_2864, _2958);\n    float _2965 = _2874.y;\n    if (_2962 < _2965)\n    {\n        return 1.0;\n    }\n    vec2 _2980 = vec2(dot(fa_light_texel(param_4), _2958), dot(fa_light_texel(param_5), _2958)) / vec2(_2962);\n    float _2982 = _2980.x;\n    bool _2985 = _2982 < _2869.x;\n    bool _2994;\n    if (!_2985)\n    {\n        _2994 = _2982 > _2869.z;\n    }\n    else\n    {\n        _2994 = _2985;\n    }\n    bool _3003;\n    if (!_2994)\n    {\n        _3003 = _2980.y < _2869.y;\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    bool _3012;\n    if (!_3003)\n    {\n        _3012 = _2980.y > _2869.w;\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        return 1.0;\n    }\n    float _3018 = _2806.x;\n    float _3020;\n    if (_3018 > 0.0)\n    {\n        _3020 = _3018;\n    }\n    else\n    {\n        _3020 = 1.5 * _2886;\n    }\n    vec2 param_9 = _2980;\n    vec4 param_10 = _2869;\n    float param_11 = _2962 - (_3020 * (1.0 + (0.5 * _2933)));\n    float param_12 = _2886;\n    float param_13 = 1.0;\n    float param_14 = _2874.z * 0.25;\n    float param_15 = (_2886 * min(_2933, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2965, _2874.z);\n    int param_17 = int(_2801.z + 0.5);\n    float param_18 = _2801.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5171 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5178;\n    if (!_5171)\n    {\n        _5178 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5178 = _5171;\n    }\n    if (_5178)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5191 = fa_light_texel(param);\n    float _5192 = _5191.y;\n    float len = _5192;\n    if (_5192 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5204 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5214 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5204);\n    if (_5214 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5220 = len;\n    float _5223 = min(_5220, 0.89999997615814208984375 * dist);\n    len = _5223;\n    float _5228 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5204);\n    float _5233 = _5228 + (0.5 * _5223);\n    vec3 _5239 = world + (gn * _5228);\n    float _5241 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5305;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5256 = (float(k) + _5241) * 0.083333335816860198974609375;\n        vec3 _5264 = _5239 + (l * (_5256 * len));\n        vec4 _5270 = vec4(_5264, 1.0);\n        float _5276 = dot(fa_mesh_fs_params[28], _5270);\n        if (_5276 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5296 = vec2(dot(fa_mesh_fs_params[26], _5270), dot(fa_mesh_fs_params[27], _5270)) / vec2(_5276);\n        float _5300 = _5296.x * 0.5;\n        float _5301 = _5300 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5305 = (_5296.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5305 = 0.5 - (_5296.y * 0.5);\n        }\n        bool _5321 = _5301 < 0.0;\n        bool _5328;\n        if (!_5321)\n        {\n            _5328 = _5301 >= 1.0;\n        }\n        else\n        {\n            _5328 = _5321;\n        }\n        bool _5335;\n        if (!_5328)\n        {\n            _5335 = _5305 < 0.0;\n        }\n        else\n        {\n            _5335 = _5328;\n        }\n        bool _5342;\n        if (!_5335)\n        {\n            _5342 = _5305 >= 1.0;\n        }\n        else\n        {\n            _5342 = _5335;\n        }\n        if (_5342)\n        {\n            break;\n        }\n        vec4 _5369 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5301, _5305) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5369.w < 0.5)\n        {\n            continue;\n        }\n        float _5388 = (dot(fa_mesh_fs_params[29].xyz, _5264) + fa_mesh_fs_params[29].w) - _5369.x;\n        if ((_5388 > _5228) && (_5388 < _5233))\n        {\n            occ = max(occ, (1.0 - (_5256 * _5256)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5301, 0.5 - _5300), min(_5305, 1.0 - _5305))));\n        }\n    }\n    return 1.0 - (occ * _5214);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5854 = fa_baked_keep(param);\n    if (_5854 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5880 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9025 = _5880.color;\n    float _9026 = _5880.attenuation;\n    float _9027 = _5880.shadow;\n    bool _5883 = _5880.type == 0;\n    if (_5883 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5880.direction;\n        float _5894 = fa_shadow_factor(param_5, param_6);\n        _9027 = _5894;\n        _9025 *= _5894;\n    }\n    else\n    {\n        bool _5905 = _5880.type != 0;\n        bool _5911;\n        if (_5905)\n        {\n            _5911 = _9026 > 0.0;\n        }\n        else\n        {\n            _5911 = _5905;\n        }\n        if (_5911)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5880.direction;\n            float _5930 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9027 = _5930;\n            _9025 *= _5930;\n        }\n    }\n    bool _5940 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5946;\n    if (_5940)\n    {\n        _5946 = _9026 > 0.0;\n    }\n    else\n    {\n        _5946 = _5940;\n    }\n    if (_5946)\n    {\n        float _5953;\n        if (_5883)\n        {\n            _5953 = 1000000000.0;\n        }\n        else\n        {\n            _5953 = _5880._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5880.direction;\n        float param_18 = _5953;\n        float _5971 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9027 *= _5971;\n        _9025 *= _5971;\n    }\n    float _5984 = _9026;\n    float _5985 = _5984 * _5854;\n    _9026 = _5985;\n    vec3 _5989 = _9025;\n    vec3 _5990 = _5989 * _5854;\n    _9025 = _5990;\n    return LightSample(_5880.direction, _5990, _5985, _9027, _5880._distance, _5880.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6024 = v - (n * dot(v, n));\n    vec3 t = _6024;\n    float _6028 = dot(_6024, _6024);\n    float l2 = _6028;\n    if (_6028 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6038;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6038 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6038 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6038;\n        l2 = dot(_6038, _6038);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6073 = dot(a, a);\n    float _6077 = dot(b, b);\n    if ((_6073 < 1.0000000195414813782625560981111e-24) || (_6077 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6091 = a * inversesqrt(_6073);\n    vec3 _6096 = b * inversesqrt(_6077);\n    float _6100 = dot(_6091, _6096);\n    float _6103 = abs(_6100);\n    float g = (((((((((((0.0416471660137176513671875 * _6103) - 0.1924748718738555908203125) * _6103) + 0.4179156124591827392578125) * _6103) - 0.616057217121124267578125) * _6103) + 0.777722418308258056640625) * _6103) - 0.999542415142059326171875) * _6103) + 1.570791721343994140625;\n    if (_6100 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6100 * _6100), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6091, _6096) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6160 = a.z > 0.0;\n    bool _6164 = b.z > 0.0;\n    if (_6160 && _6164)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6160 != _6164)\n        {\n            vec3 _6199 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6199.z = 0.0;\n            if (_6160)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6199;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6199;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6199;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6199;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6248 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6274 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6300 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6326 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6248;\n    vec3 param_1 = _6274;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6274;\n    vec3 param_7 = _6300;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6300;\n    vec3 param_13 = _6326;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6326;\n    vec3 param_19 = _6248;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6475 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6499 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6515 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6475;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6499;\n    vec4 param_9 = m;\n    vec3 param_10 = _6475;\n    vec3 param_11 = _6499;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6515;\n    vec4 param_14 = m;\n    vec3 param_15 = _6475;\n    vec3 param_16 = _6515;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6573 = fa_light_base(param);\n    int param_1 = _6573;\n    int param_2 = _6573 + 1;\n    int param_3 = _6573 + 2;\n    int param_4 = _6573 + 4;\n    vec4 _6595 = fa_light_texel(param_4);\n    int param_5 = _6573 + 5;\n    vec4 _6600 = fa_light_texel(param_5);\n    int param_6 = _6573 + 6;\n    vec4 _6605 = fa_light_texel(param_6);\n    float _6606 = _6605.w;\n    vec3 _6611 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6613 = _6606 < 1.5;\n    bool _6620;\n    if (_6613)\n    {\n        _6620 = dot(normalize(fa_light_texel(param_3).xyz), _6611) >= 0.0;\n    }\n    else\n    {\n        _6620 = _6613;\n    }\n    if (_6620)\n    {\n        return vec3(0.0);\n    }\n    bool _6629 = (_6606 > 0.5) && _6613;\n    float _6633 = _6629 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6636 = _6595.xyz;\n    float _6638 = _6595.w;\n    vec3 _6644 = _6600.xyz;\n    float _6646 = _6600.w;\n    vec3 up = _6644 * (_6646 * _6633);\n    float _6652;\n    if (_6629)\n    {\n        _6652 = (3.1415927410125732421875 * _6638) * _6638;\n    }\n    else\n    {\n        _6652 = (4.0 * _6638) * _6646;\n    }\n    if (_6606 > 1.5)\n    {\n        vec3 _6678 = cross(_6636, -_6611);\n        vec3 perp = _6678;\n        float _6682 = dot(_6678, _6678);\n        vec3 _6685;\n        if (_6682 > 1.0000000133514319600180897396058e-10)\n        {\n            _6685 = perp * inversesqrt(_6682);\n        }\n        else\n        {\n            _6685 = _6644;\n        }\n        perp = _6685;\n        up = _6685 * _6646;\n    }\n    float _6706 = max(_6652, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6716 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6716;\n    vec3 param_10 = n;\n    vec3 param_11 = _6611;\n    vec3 _6724 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6716;\n    vec3 param_13 = n;\n    vec3 param_14 = _6636 * (_6638 * _6633);\n    vec3 _6732 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6716;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6740 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6606;\n    vec3 param_20 = _6724;\n    vec3 param_21 = _6732;\n    vec3 param_22 = _6740;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6759 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6759;\n    vec2 param_26 = _6759 + vec2(64.0, 0.0);\n    vec4 _6769 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6606;\n    vec3 param_29 = _6724;\n    vec3 param_30 = _6732;\n    vec3 param_31 = _6740;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6769.x) + ((vec3(f90) - f0) * _6769.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6611, _6611)) + _6706) / _6706) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4908 = 1.0 / alpha;\n    return ((2.0 + _4908) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4908)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4943 = max(dot(L.nc, l), 0.0);\n    float _4949 = max(dot(L.nc, h), 0.0);\n    float _4958 = ((_4949 * _4949) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4958) * _4958)) * (0.5 / max(mix((2.0 * _4943) * L.coat_ndv, _4943 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4943)) * _4943;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6837;\n    if (L.sheen_on)\n    {\n        _6837 = L.sheen_scale;\n    }\n    else\n    {\n        _6837 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6837);\n    vec3 _6850 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6861 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6870 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6850), 0.0);\n        float param_13 = _6870;\n        float param_14 = ndv;\n        result += ((L.sheen * _6861) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6870)) * _6870) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6850;\n        float param_18 = max(dot(v, _6850), 0.0);\n        result += (_6861 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4811 = tdh / at;\n    float _4815 = bdh / ab;\n    float _4827 = ((_4811 * _4811) + (_4815 * _4815)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4827) * _4827);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5007 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5086 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5086) * _5086);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5007);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5007));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4210 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4213 = _4210.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4213 * _4213, exp2((-9.27999973297119140625) * ndv)) * _4213) + _4210.y)) + _4210.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3518;\n    if (lv == 0)\n    {\n        _3518 = 0.0;\n    }\n    else\n    {\n        _3518 = res + 2.0;\n    }\n    float _3528;\n    if (lv == 0)\n    {\n        _3528 = 0.0;\n    }\n    else\n    {\n        _3528 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3518, _3528)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3574;\n    if (res > 64.5)\n    {\n        _3574 = 5.0;\n    }\n    else\n    {\n        _3574 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3589 = clamp(rough, 0.0, 1.0) * (_3574 - 1.0);\n    int _3596 = int(min(floor(_3589), _3574 - 2.0));\n    float _3601 = _3589 - float(_3596);\n    vec3 param = d;\n    vec2 _3605 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3596;\n    vec2 param_4 = _3605;\n    vec3 _3615 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3601 < 0.00200000009499490261077880859375)\n    {\n        return _3615;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3596 + 1;\n    vec2 param_8 = _3605;\n    return mix(_3615, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3601));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3688 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3695 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3702 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3708 = dot(bx.xyz, d);\n    float _3712 = dot(by.xyz, d);\n    float _3716 = dot(bz.xyz, d);\n    float _3722;\n    if (_3708 > 9.9999999747524270787835121154785e-07)\n    {\n        _3722 = (1.0 - _3688) / _3708;\n    }\n    else\n    {\n        float _3736;\n        if (_3708 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3736 = ((-1.0) - _3688) / _3708;\n        }\n        else\n        {\n            _3736 = 1000000015047466219876688855040.0;\n        }\n        _3722 = _3736;\n    }\n    float tx = _3722;\n    float _3753;\n    if (_3712 > 9.9999999747524270787835121154785e-07)\n    {\n        _3753 = (1.0 - _3695) / _3712;\n    }\n    else\n    {\n        float _3766;\n        if (_3712 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3766 = ((-1.0) - _3695) / _3712;\n        }\n        else\n        {\n            _3766 = 1000000015047466219876688855040.0;\n        }\n        _3753 = _3766;\n    }\n    float ty = _3753;\n    float _3782;\n    if (_3716 > 9.9999999747524270787835121154785e-07)\n    {\n        _3782 = (1.0 - _3702) / _3716;\n    }\n    else\n    {\n        float _3795;\n        if (_3716 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3795 = ((-1.0) - _3702) / _3716;\n        }\n        else\n        {\n            _3795 = 1000000015047466219876688855040.0;\n        }\n        _3782 = _3795;\n    }\n    float _3807 = tx;\n    float _3810 = (_3807 > 0.0) ? _3807 : 1000000015047466219876688855040.0;\n    tx = _3810;\n    float _3811 = ty;\n    float _3814 = (_3811 > 0.0) ? _3811 : 1000000015047466219876688855040.0;\n    ty = _3814;\n    float _3824 = min(_3810, min(_3814, (_3782 > 0.0) ? _3782 : 1000000015047466219876688855040.0));\n    if (_3824 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3840 = (fa_world_pos + (d * _3824)) - posw.xyz;\n    vec3 _3845;\n    if (dot(_3840, _3840) > 1.0000000133514319600180897396058e-10)\n    {\n        _3845 = normalize(_3840);\n    }\n    else\n    {\n        _3845 = d;\n    }\n    return _3845;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3891 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3891 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3919 = rough * rough;\n            float _3950 = 0.60000002384185791015625 * _3919;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3919)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3950, 0.0500000007450580596923828125 + _3950, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3919 * 0.60000002384185791015625));\n        }\n        outc = base * _3891;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4009 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4009 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4041 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4041 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4688;\n        if (L.aniso >= 0.0)\n        {\n            _4688 = L.b;\n        }\n        else\n        {\n            _4688 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4688, v), _4688), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4724 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4724.x) + (vec3(L.f90) * _4724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4782 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4782.x) + _4782.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4252 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4252.x) + vec3(_4252.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5492 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5496 = fa_xm_origin(param_1);\n    vec2 _5502 = (uv * _5492) - vec2(0.5);\n    vec2 _5505 = fract(_5502);\n    vec2 _5508 = floor(_5502);\n    vec2 param_2 = _5492;\n    vec2 param_3 = _5496;\n    vec2 param_4 = _5508;\n    vec2 param_5 = _5492;\n    vec2 param_6 = _5496;\n    vec2 param_7 = _5508 + vec2(1.0, 0.0);\n    vec2 param_8 = _5492;\n    vec2 param_9 = _5496;\n    vec2 param_10 = _5508 + vec2(0.0, 1.0);\n    vec2 param_11 = _5492;\n    vec2 param_12 = _5496;\n    vec2 param_13 = _5508 + vec2(1.0);\n    vec3 _5550 = vec3(_5505.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5550), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5550), vec3(_5505.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5569 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5573 = clamp(lod, 0.0, _5569);\n    int _5577 = int(floor(_5573));\n    int param = _5577;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5587 = float(_5577);\n    float _5588 = _5573 - _5587;\n    bool _5590 = _5588 > 0.001000000047497451305389404296875;\n    bool _5597;\n    if (_5590)\n    {\n        _5597 = _5587 < _5569;\n    }\n    else\n    {\n        _5597 = _5590;\n    }\n    if (_5597)\n    {\n        int param_2 = _5577 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5588));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5623 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5623.x) + (vec3(f90) * _5623.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5651 = max(s.thickness, 0.0);\n    bool _5656 = _5651 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5656)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5651);\n    }\n    bool _5681 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5688;\n    if (!_5681)\n    {\n        _5688 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5688 = _5681;\n    }\n    if (_5688)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5656)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5651);\n    }\n    vec4 _5723 = vec4(world, 1.0);\n    float _5728 = dot(fa_mesh_fs_params[28], _5723);\n    vec2 uv = vec2(0.5);\n    if (_5728 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5746 = vec2(dot(fa_mesh_fs_params[26], _5723), dot(fa_mesh_fs_params[27], _5723)) / vec2(_5728);\n        float _5754;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5754 = (_5746.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5754 = 0.5 - (_5746.y * 0.5);\n        }\n        uv = vec2((_5746.x * 0.5) + 0.5, _5754);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3269 = int(fa_shadows[25].x + 0.5);\n    float _3279 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3284 = _3269 > 0;\n    bool _3293;\n    if (_3284)\n    {\n        int param = _3269 - 1;\n        _3293 = _3279 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3293 = _3284;\n    }\n    if (_3293)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3299 = _3269 > 1;\n        bool _3306;\n        if (_3299)\n        {\n            _3306 = _3279 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3306 = _3299;\n        }\n        if (_3306)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3312 = _3269 > 2;\n        bool _3319;\n        if (_3312)\n        {\n            _3319 = _3279 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3319 = _3312;\n        }\n        if (_3319)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3325 = _3269 > 3;\n        bool _3332;\n        if (_3325)\n        {\n            _3332 = _3279 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3332 = _3325;\n        }\n        if (_3332)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8684 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8684 = -_8684;\n    }\n    vec3 _7975 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8684, fa_world_tangent, fa_uv, fa_vertex_color, _7975, gl_FrontFacing);\n    Surface _7983 = fa_standard_surface(param_1);\n    vec3 _8715 = _7983.albedo;\n    float _8716 = _7983.alpha;\n    vec3 _8717 = _7983.normal;\n    float _8718 = _7983.metallic;\n    float _8719 = _7983.roughness;\n    float _8720 = _7983.occlusion;\n    vec3 _8721 = _7983.emission;\n    float _8722 = _7983.clearcoat;\n    float _8723 = _7983.clearcoat_roughness;\n    vec3 _8724 = _7983.sheen_color;\n    float _8725 = _7983.sheen_roughness;\n    float _8726 = _7983.anisotropy;\n    float _8727 = _7983.anisotropy_rotation;\n    float _8728 = _7983.specular;\n    float _8729 = _7983.ior;\n    vec3 _8730 = _7983.specular_color;\n    float _8731 = _7983.transmission;\n    float _8732 = _7983.thickness;\n    vec3 _8733 = _7983.attenuation_color;\n    float _8734 = _7983.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8684, fa_world_tangent, fa_uv, fa_vertex_color, _7975, gl_FrontFacing);\n    Surface param_3 = _7983;\n    surface(param_2, param_3);\n    _8715 = param_3.albedo;\n    _8716 = param_3.alpha;\n    _8717 = param_3.normal;\n    _8718 = param_3.metallic;\n    _8719 = param_3.roughness;\n    _8720 = param_3.occlusion;\n    _8721 = param_3.emission;\n    _8722 = param_3.clearcoat;\n    _8723 = param_3.clearcoat_roughness;\n    _8724 = param_3.sheen_color;\n    _8725 = param_3.sheen_roughness;\n    _8726 = param_3.anisotropy;\n    _8727 = param_3.anisotropy_rotation;\n    _8728 = param_3.specular;\n    _8729 = param_3.ior;\n    _8730 = param_3.specular_color;\n    _8731 = param_3.transmission;\n    _8732 = param_3.thickness;\n    _8733 = param_3.attenuation_color;\n    _8734 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8684;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8715 = param_6;\n    _8717 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8715;\n    }\n    else\n    {\n        vec3 _8023 = normalize(_8717);\n        float _8030 = clamp(_8718, 0.0, 1.0);\n        float _8034 = clamp(_8719, 0.0500000007450580596923828125, 1.0);\n        float _8038 = _8034 * _8034;\n        float _8042 = _8038 * _8038;\n        float _8047 = max(dot(_8023, _7975), 9.9999997473787516355514526367188e-05);\n        float _8053 = 1.0 - _8030;\n        float _8054 = clamp(_8731, 0.0, 1.0) * _8053;\n        vec3 _8063 = (_8715 * _8053) * (1.0 - _8054);\n        vec3 _8070 = mix(vec3(0.039999999105930328369140625), _8715, vec3(_8030));\n        vec3 f0 = _8070;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8684, fa_world_tangent, fa_uv, fa_vertex_color, _7975, gl_FrontFacing);\n        Surface param_9 = Surface(_8715, _8716, _8717, _8718, _8719, _8720, _8721, _8722, _8723, _8724, _8725, _8726, _8727, _8728, _8729, _8730, _8731, _8732, _8733, _8734);\n        vec3 param_10 = _8023;\n        vec3 param_11 = _7975;\n        float param_12 = _8030;\n        float param_13 = _8034;\n        vec3 param_14 = _8070;\n        FaLayers _8086 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8023;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8063) * _8720;\n        if (_8086.on)\n        {\n            lit *= _8086.base_scale;\n        }\n        int _8108 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8108; ln++)\n        {\n            int param_16 = ln;\n            int _8121 = fa_cl_light(param_16);\n            int param_17 = _8121;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8121;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8684;\n            LightSample _8137 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8145 = max(dot(_8023, _8137.direction), 0.0);\n            float _8151 = _8137.attenuation * _8137.shadow;\n            vec3 _8156 = normalize(_8137.direction + _7975);\n            float _8161 = max(dot(_8023, _8156), 0.0);\n            float _8166 = max(dot(_7975, _8156), 0.0);\n            bool _8173;\n            if (fa_light_is_area)\n            {\n                _8173 = !_8086.on;\n            }\n            else\n            {\n                _8173 = fa_light_is_area;\n            }\n            if (_8173)\n            {\n                int param_21 = _8121;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8023;\n                vec3 param_24 = _7975;\n                vec3 param_25 = _8063;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _8034;\n                float param_29 = _8047;\n                float param_30 = _8151;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8086;\n                    int param_32 = _8121;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _8023;\n                    vec3 param_35 = _7975;\n                    vec3 param_36 = _8137.direction;\n                    vec3 param_37 = _8063;\n                    vec3 param_38 = f0;\n                    float param_39 = _8034;\n                    float param_40 = _8047;\n                    float param_41 = _8151;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8086.on)\n                    {\n                        FaLayers param_42 = _8086;\n                        vec3 param_43 = _8063;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _8023;\n                        vec3 param_46 = _7975;\n                        vec3 param_47 = _8137.direction;\n                        vec3 param_48 = _8156;\n                        float param_49 = _8145;\n                        float param_50 = _8047;\n                        float param_51 = _8161;\n                        float param_52 = _8166;\n                        float param_53 = _8038;\n                        float param_54 = _8042;\n                        int param_55 = _8121;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8151));\n                    }\n                    else\n                    {\n                        float _8279 = ((_8161 * _8161) * (_8042 - 1.0)) + 1.0;\n                        int param_56 = _8121;\n                        lit += (((_8063 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8166, 5.0))) * (((_8042 / ((3.1415927410125732421875 * _8279) * _8279)) * (0.5 / max(mix((2.0 * _8145) * _8047, _8145 + _8047, _8038), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8145))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8145 * _8151));\n                    }\n                }\n            }\n        }\n        if (_8086.on)\n        {\n            FaLayers param_57 = _8086;\n            vec3 param_58 = _8023;\n            vec3 param_59 = _7975;\n            vec3 param_60 = f0;\n            float param_61 = _8034;\n            float param_62 = _8720;\n            lit += fa_layers_ibl(param_57, param_58, param_59, param_60, param_61, param_62);\n        }\n        else\n        {\n            vec3 param_63 = _8023;\n            vec3 param_64 = _7975;\n            vec3 param_65 = f0;\n            float param_66 = _8034;\n            lit += (fa_sky_reflection(param_63, param_64, param_65, param_66) * _8720);\n        }\n        if (_8054 > 0.0)\n        {\n            float _8377;\n            if (_8086.on)\n            {\n                _8377 = _8086.f90;\n            }\n            else\n            {\n                _8377 = 1.0;\n            }\n            float _8385;\n            if (_8086.on)\n            {\n                _8385 = _8086.base_scale;\n            }\n            else\n            {\n                _8385 = 1.0;\n            }\n            Surface param_67 = Surface(_8715, _8716, _8717, _8718, _8719, _8720, _8721, _8722, _8723, _8724, _8725, _8726, _8727, _8728, _8729, _8730, _8731, _8732, _8733, _8734);\n            vec3 param_68 = _8023;\n            vec3 param_69 = _7975;\n            float param_70 = _8034;\n            vec3 param_71 = f0;\n            float param_72 = _8377;\n            float param_73 = _8385;\n            float param_74 = _8054;\n            float param_75 = fa_tr_blend;\n            vec3 _8409 = fa_transmitted(param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74, param_75);\n            fa_tr_blend = param_75;\n            lit += _8409;\n        }\n        result = lit;\n    }\n    vec3 _8416 = result;\n    vec3 _8417 = _8416 + _8721;\n    result = _8417;\n    vec3 param_76 = _8417;\n    vec3 param_77 = fa_world_pos;\n    result = fa_shadow_debug(param_76, param_77);\n    bool _8426 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8433;\n    if (!_8426)\n    {\n        _8433 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8433 = _8426;\n    }\n    if (_8433)\n    {\n        vec3 _8442 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8448 = dot(_8442, fa_mesh_fs_params[9].xyz);\n        bool _8452 = fa_mesh_fs_params[9].w > 0.5;\n        float _8453;\n        if (_8452)\n        {\n            _8453 = _8448;\n        }\n        else\n        {\n            _8453 = length(_8442);\n        }\n        float _8465 = _8453 - fa_mesh_fs_params[8].x;\n        if (_8465 > 0.0)\n        {\n            float _8474 = fa_mesh_fs_params[7].w * _8465;\n            float tau = _8474 * _8474;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8490;\n                if (_8452)\n                {\n                    _8490 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8448);\n                }\n                else\n                {\n                    _8490 = fa_mesh_fs_params[0].y;\n                }\n                float _8511 = mix(_8490, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8453, 0.0, 1.0));\n                float _8515 = fa_world_pos.y - _8511;\n                float _8520 = _8511 - fa_mesh_fs_params[8].z;\n                float _8525 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8528 = _8520 <= 0.0;\n                bool _8529 = !_8528;\n                bool _8535;\n                if (_8529)\n                {\n                    _8535 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8535 = _8528;\n                }\n                float _8536;\n                if (_8535)\n                {\n                    _8536 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8536 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8520, 80.0));\n                }\n                bool _8563;\n                if (_8529)\n                {\n                    _8563 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8563 = _8528;\n                }\n                float _8564;\n                if (_8563)\n                {\n                    _8564 = fa_mesh_fs_params[8].y * _8520;\n                }\n                else\n                {\n                    _8564 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8520, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8589 = _8525 <= 0.0;\n                bool _8596;\n                if (!_8589)\n                {\n                    _8596 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8596 = _8589;\n                }\n                float _8597;\n                if (_8596)\n                {\n                    _8597 = fa_mesh_fs_params[8].y * _8525;\n                }\n                else\n                {\n                    _8597 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8525, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8624;\n                if (abs(_8515) < 0.001000000047497451305389404296875)\n                {\n                    _8624 = _8536;\n                }\n                else\n                {\n                    _8624 = (_8597 - _8564) / _8515;\n                }\n                tau += (_8465 * max(_8624, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8660 = 1.0 - fa_tr_blend;\n        result /= vec3(_8660);\n        _8716 *= _8660;\n    }\n    fa_frag_color = vec4(result, _8716);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
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
            "inst_name": "_197",
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
            "inst_name": "_653",
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
            "inst_name": "_2315",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _182 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _189 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_182 * _189).z;\n    fa_pre_r0 = vec3(_182[0].x, _182[1].x, _182[2].x);\n    fa_pre_r1 = vec3(_182[0].y, _182[1].y, _182[2].y);\n    fa_pre_r2 = vec3(_182[0].z, _182[1].z, _182[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _189;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _781 = base_t;\n    _781.x = _227.x;\n    _781.y = _227.y;\n    _781.z = _227.z;\n    base_t = _781;\n    vec4 _243 = (_781 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _736 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _789 = _281;\n        _789.x = _286.x;\n        _789.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _789;\n        _736 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _792 = mrt;\n    _792.x = _315.x;\n    _792.y = _315.y;\n    _792.z = _315.z;\n    mrt = _792;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _741 = fa_mesh_fs_params[20].x;\n    float _742 = fa_mesh_fs_params[20].y;\n    float _745 = fa_mesh_fs_params[20].z;\n    float _744 = fa_mesh_fs_params[21].w;\n    float _747 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _741 *= _357.y;\n            _742 *= _357.z;\n            _744 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _745 *= mrt.x;\n            _747 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _736, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _741, _742, fa_mesh_fs_params[21].xyz, _744, _745, fa_mesh_fs_params[20].w, _747, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _631 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _631 = -_631;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _631, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _631, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_188 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_188 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_188 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _295 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _302 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_295 * _302).z;\n    fa_pre_r0 = vec3(_295[0].x, _295[1].x, _295[2].x);\n    fa_pre_r1 = vec3(_295[0].y, _295[1].y, _295[2].y);\n    fa_pre_r2 = vec3(_295[0].z, _295[1].z, _295[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _302;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _781 = base_t;\n    _781.x = _227.x;\n    _781.y = _227.y;\n    _781.z = _227.z;\n    base_t = _781;\n    vec4 _243 = (_781 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _736 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _789 = _281;\n        _789.x = _286.x;\n        _789.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _789;\n        _736 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _792 = mrt;\n    _792.x = _315.x;\n    _792.y = _315.y;\n    _792.z = _315.z;\n    mrt = _792;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _741 = fa_mesh_fs_params[20].x;\n    float _742 = fa_mesh_fs_params[20].y;\n    float _745 = fa_mesh_fs_params[20].z;\n    float _744 = fa_mesh_fs_params[21].w;\n    float _747 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _741 *= _357.y;\n            _742 *= _357.z;\n            _744 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _745 *= mrt.x;\n            _747 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _736, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _741, _742, fa_mesh_fs_params[21].xyz, _744, _745, fa_mesh_fs_params[20].w, _747, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _631 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _631 = -_631;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _631, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _631, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
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
            "inst_name": "_197",
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
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_36",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
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
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _179 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_179 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_179 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_179 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 7,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 8,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_41",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
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
            "inst_name": "_188",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ]
      }
    }
  }
}

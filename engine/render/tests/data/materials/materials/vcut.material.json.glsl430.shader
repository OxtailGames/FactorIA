{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "08807f15fbf8385ded2b4420996b416372731eb6a03ea417de2ef212814a9452",
  "slang": "glsl430",
  "params": [
    "alphaCutoff"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4853[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1635 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    bool _1650;\n    if (!_1642)\n    {\n        _1650 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1650 = _1642;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    bool _1664;\n    if (!_1657)\n    {\n        _1664 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1664 = _1657;\n    }\n    if (_1664)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1674 = vec4(world_pos, 1.0);\n    float _1680 = dot(fa_mesh_fs_params[16], _1674);\n    if (!(_1680 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1702 = vec2(dot(fa_mesh_fs_params[14], _1674), dot(fa_mesh_fs_params[15], _1674)) / vec2(_1680);\n    int _1706 = int(fa_mesh_fs_params[18].x);\n    int _1710 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1710) + clamp(int(floor(((_1702.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1710 - 1)) * _1706)) + clamp(int(floor(((_1702.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1706 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1786 = fa_cluster_texel(param);\n    return ivec2(int(_1786.x), int(_1786.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6487 = fa_cluster_lookup(param);\n    fa_cl_slot = _6487.x;\n    fa_cl_local = _6487.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7646 = fa_linear_to_srgb(param);\n        c = _7646;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7654 = fa_srgb_to_linear(param_1);\n            c = _7654;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _541;\n    if (i.front_facing)\n    {\n        _541 = i.world_normal;\n    }\n    else\n    {\n        _541 = -i.world_normal;\n    }\n    vec3 _565 = normalize(i.world_tangent.xyz - (_541 * dot(_541, i.world_tangent.xyz)));\n    vec3 _592 = normalize(((_565 * m.x) + ((cross(_541, _565) * i.world_tangent.w) * m.y)) + (_541 * m.z));\n    vec3 _595;\n    if (i.front_facing)\n    {\n        _595 = _592;\n    }\n    else\n    {\n        _595 = -_592;\n    }\n    return _595;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7686 = fa_tex_fix(param_2, param_3);\n    vec4 _10068 = base_t;\n    _10068.x = _7686.x;\n    _10068.y = _7686.y;\n    _10068.z = _7686.z;\n    base_t = _10068;\n    vec4 _7700 = (_10068 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9818 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7734 = fa_tex_fix(param_6, param_7);\n        vec3 _7737 = (_7734 * 2.0) - vec3(1.0);\n        vec2 _7742 = _7737.xy * fa_mesh_fs_params[6].x;\n        vec3 _10076 = _7737;\n        _10076.x = _7742.x;\n        _10076.y = _7742.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10076;\n        _9818 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7772 = fa_tex_fix(param_12, param_13);\n    vec4 _10079 = mrt;\n    _10079.x = _7772.x;\n    _10079.y = _7772.y;\n    _10079.z = _7772.z;\n    mrt = _10079;\n    vec4 _7802 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7802.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7813 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7845 = fa_tex_fix(param_20, param_21);\n    float _9823 = fa_mesh_fs_params[20].x;\n    float _9824 = fa_mesh_fs_params[20].y;\n    float _9827 = fa_mesh_fs_params[20].z;\n    float _9826 = fa_mesh_fs_params[21].w;\n    float _9829 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9823 *= _7813.y;\n            _9824 *= _7813.z;\n            _9826 *= _7802.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9827 *= mrt.x;\n            _9829 *= mrt.w;\n        }\n    }\n    return Surface(_7700.xyz, _7700.w, _9818, clamp(fa_mesh_fs_params[5].x * _7772.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7772.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7813.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7845), _9823, _9824, fa_mesh_fs_params[21].xyz, _9826, _9827, fa_mesh_fs_params[20].w, _9829, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1866 = rect.zw - rect.xy;\n    vec2 _1870 = _1866 * atlas;\n    vec2 _1874 = ddx * _1870;\n    vec2 _1878 = ddy * _1870;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1866), clamp(0.5 * log2(max(max(dot(_1874, _1874), dot(_1878, _1878)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1911 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1918;\n    if (!_1911)\n    {\n        _1918 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1918 = _1911;\n    }\n    if (_1918)\n    {\n        return;\n    }\n    vec3 _1924 = dFdx(world_pos);\n    vec3 _1927 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1931 = fa_cluster_texel(param);\n    int _1935 = int(_1931.w);\n    if (_1935 < 1)\n    {\n        return;\n    }\n    int _1945 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1945;\n    vec4 _1949 = fa_light_texel(param_1);\n    vec2 _1952 = _1949.yz;\n    int _1956 = int(_1949.w);\n    int param_2 = _1945 + 1;\n    vec4 _1961 = fa_light_texel(param_2);\n    float _1962 = _1961.x;\n    int _1968 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1972 = int(_1931.z);\n    vec3 _2237;\n    for (int k = 0; k < _1935; k++)\n    {\n        int _1985 = _1972 + k;\n        int param_3 = _1956 + (_1985 >> 2);\n        int _2002 = (_1945 + 2) + (int(fa_light_texel(param_3)[_1985 & 3]) * 7);\n        int param_4 = _2002 + 6;\n        vec4 _2007 = fa_light_texel(param_4);\n        if (((int(_2007.w + 0.5) >> _1968) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2002;\n        vec4 _2022 = fa_light_texel(param_5);\n        int param_6 = _2002 + 1;\n        vec4 _2027 = fa_light_texel(param_6);\n        int param_7 = _2002 + 2;\n        vec4 _2032 = fa_light_texel(param_7);\n        vec3 _2035 = _2022.xyz;\n        float _2040 = dot(_2035, world_pos) + _2022.w;\n        vec3 _2042 = _2027.xyz;\n        float _2047 = dot(_2042, world_pos) + _2027.w;\n        vec3 _2049 = _2032.xyz;\n        float _2054 = dot(_2049, world_pos) + _2032.w;\n        bool _2059 = abs(_2040) > 0.5;\n        bool _2067;\n        if (!_2059)\n        {\n            _2067 = abs(_2047) > 0.5;\n        }\n        else\n        {\n            _2067 = _2059;\n        }\n        bool _2075;\n        if (!_2067)\n        {\n            _2075 = abs(_2054) > 0.5;\n        }\n        else\n        {\n            _2075 = _2067;\n        }\n        if (_2075)\n        {\n            continue;\n        }\n        float _2090 = clamp(dot(geo_normal, normalize(_2049)) * _2007.z, 0.0, 1.0);\n        if (_2090 <= 0.0)\n        {\n            continue;\n        }\n        float _2110 = (clamp((0.5 - abs(_2054)) * 10.0, 0.0, 1.0) * _2090) * _2007.x;\n        vec2 _2118 = vec2(_2040 + 0.5, 0.5 - _2047);\n        vec2 _2128 = vec2(dot(_2035, _1924), dot(_2042, _1924));\n        vec2 _2138 = vec2(dot(_2035, _1927), dot(_2042, _1927));\n        int param_8 = _2002 + 5;\n        vec4 _2143 = fa_light_texel(param_8);\n        int param_9 = _2002 + 3;\n        vec4 _2148 = fa_light_texel(param_9);\n        int param_10 = _2002 + 4;\n        vec4 _2153 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2143.xyz;\n        bool _2163 = _2148.z > _2148.x;\n        if (_2163)\n        {\n            vec4 param_11 = _2148;\n            vec2 param_12 = _2118;\n            vec2 param_13 = _1952;\n            vec2 param_14 = _2128;\n            vec2 param_15 = _2138;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1962 > 0.5) && (_1962 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2189 = fa_dc_to_linear(param_16);\n                vec4 _9906 = tx;\n                _9906.x = _2189.x;\n                _9906.y = _2189.y;\n                _9906.z = _2189.z;\n                tx = _9906;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2110 * tex_a) * _2143.w, 0.0, 1.0)));\n        if (_2153.z > _2153.x)\n        {\n            vec4 param_17 = _2153;\n            vec2 param_18 = _2118;\n            vec2 param_19 = _1952;\n            vec2 param_20 = _2128;\n            vec2 param_21 = _2138;\n            vec4 _2233 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1962 > 1.5)\n            {\n                vec3 param_22 = _2233.xyz;\n                vec3 _2243 = fa_dc_to_srgb(param_22);\n                _2237 = _2243;\n            }\n            else\n            {\n                _2237 = _2233.xyz;\n            }\n            vec3 _2252 = (_2237 * 2.0) - vec3(1.0);\n            vec2 _2257 = _2252.xy * _2007.y;\n            vec3 _2279 = (normalize(_2035) * _2257.x) + (normalize(_2042) * _2257.y);\n            vec3 _2282 = normalize(normal);\n            normal = normalize(mix(_2282, normalize((_2282 * max(_2252.z, 0.0500000007450580596923828125)) + (_2279 - (_2282 * dot(_2282, _2279)))), vec3(clamp(_2110 * (_2163 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _631 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _634;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _634 = _631 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _634 = _631 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_634)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4778 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4786 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4789 = int(_4778);\n    int _4792 = int(_4786);\n    float _4802 = _4786 - float(_4792);\n    int _4857 = (_4789 * 9) + _4792;\n    int _4877 = ((_4789 + 1) * 9) + _4792;\n    return mix(mix(_4853[_4857], _4853[_4857 + 1], _4802), mix(_4853[_4877], _4853[_4877 + 1], _4802), _4778 - float(_4789));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9741 = false;\n    float _9742 = 1.0;\n    float _9743 = 1.0;\n    float _9744 = 1.0;\n    float _9745 = 0.0;\n    float _9746 = 0.0;\n    float _9747 = 0.0;\n    float _9748 = 0.0;\n    float _9750 = 1.0;\n    bool _9751 = false;\n    vec3 _9752 = vec3(0.0);\n    float _9753 = 1.0;\n    float _9754 = 1.0;\n    float _9755 = 1.0;\n    float _9756 = 0.0;\n    float _9757 = 0.0;\n    vec3 _9758 = vec3(1.0, 0.0, 0.0);\n    vec3 _9759 = vec3(0.0, 0.0, 1.0);\n    float _9760 = 1.0;\n    float _9761 = 1.0;\n    float _4928 = clamp(s.specular, 0.0, 1.0);\n    float _4932 = clamp(s.ior, 1.0, 3.0);\n    bool _4937 = (_4928 != 1.0) || (_4932 != 1.5);\n    bool _4946;\n    if (!_4937)\n    {\n        _4946 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4946 = _4937;\n    }\n    if (_4946)\n    {\n        float _4954 = (_4932 - 1.0) / (_4932 + 1.0);\n        f0 = mix(min(vec3(_4954 * _4954) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4928, s.albedo, vec3(metallic));\n        _9742 = mix(_4928, 1.0, metallic);\n        _9741 = true;\n    }\n    float _4981 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4981 > 0.0)\n    {\n        float _4989 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9745 = _4981;\n        _9746 = _4989;\n        float _4996 = _4989 * _4989;\n        _9747 = _4996;\n        _9748 = _4996 * _4996;\n        float _5008 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9750 = _5008;\n        _9743 = 1.0 - (_4981 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5008, 0.0, 1.0), 5.0))));\n        _9741 = true;\n    }\n    vec3 _5027 = max(s.sheen_color, vec3(0.0));\n    float _5036 = max(_5027.x, max(_5027.y, _5027.z));\n    if (_5036 > 0.0)\n    {\n        float _5044 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9751 = true;\n        _9752 = _5027;\n        _9753 = _5044;\n        _9754 = _5044 * _5044;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5044;\n        float _5061 = fa_sheen_albedo(param, param_1);\n        _9756 = _5061;\n        _9755 = 1.0 - min(_5036 * _5061, 1.0);\n        _9741 = true;\n    }\n    _9744 = _9743 * _9755;\n    float _5080 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5080 != 0.0)\n    {\n        vec3 _5095 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5095;\n        if (dot(_5095, _5095) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5107 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5107.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5107.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5107.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5111 = t;\n        vec3 _5112 = normalize(_5111);\n        t = _5112;\n        vec3 _5137 = normalize((_5112 * cos(s.anisotropy_rotation)) + ((cross(n, _5112) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9758 = _5137;\n        _9759 = cross(n, _5137);\n        float _5147 = roughness * roughness;\n        float _5153 = mix(_5147, 1.0, _5080 * _5080);\n        bool _5155 = _5080 > 0.0;\n        _9760 = _5155 ? _5153 : _5147;\n        _9761 = _5155 ? _5147 : _5153;\n        _9757 = _5080;\n        _9741 = true;\n    }\n    return FaLayers(_9741, _9742, _9743, _9744, _9745, _9746, _9747, _9748, i.world_normal, _9750, _9751, _9752, _9753, _9754, _9755, _9756, _9757, _9758, _9759, _9760, _9761);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3948 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3948;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4559 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4564 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4559 > 0.0005000000237487256526947021484375)\n    {\n        if (_4564)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4559;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4559;\n        }\n    }\n    bool _4615 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4615)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4646 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4646)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4564 || _4615) || _4646)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3968 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3971 = _3968.x;\n    float _3973 = _3968.z;\n    vec2 e = vec2(_3971, _3973);\n    if (_3968.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3973)) * ((_3971 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3971)) * ((_3973 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7955 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7960 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7965 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7970 = fa_light_texel(param_3);\n    bool _7973 = _7970.z < 0.5;\n    bool _7981;\n    if (!_7973)\n    {\n        _7981 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7981 = _7973;\n    }\n    if (_7981)\n    {\n        return vec3(0.0);\n    }\n    float _7988 = max(_7955.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7991 = _7960.xyz;\n    vec3 _7995 = _7955.xyz;\n    vec3 _7999 = (fa_world_pos - _7995) / vec3(_7988);\n    vec3 _8008 = min(_7999 + vec3(0.5), (_7991 - vec3(0.5)) - _7999);\n    float _8017 = min(_8008.x, min(_8008.y, _8008.z));\n    if (!(_8017 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8032 = _7991 - vec3(1.0);\n    vec3 _8033 = clamp(_7999, vec3(0.0), _8032);\n    vec3 _8041 = min(floor(_8033), max(_7991 - vec3(2.0), vec3(0.0)));\n    vec3 _8045 = _8033 - _8041;\n    vec3 _8056 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7988));\n    int _8061 = int(_7965.y + 0.5);\n    float _8066 = 0.3257350027561187744140625 * n.y;\n    float _8070 = 0.3257350027561187744140625 * n.z;\n    float _8074 = 0.3257350027561187744140625 * n.x;\n    float _8081 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8088 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8097 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8104 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8117 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8124 = 8 + int(_7970.w);\n    float _8151;\n    float _8164;\n    float _8178;\n    for (int k = 0; k < _8124; k++)\n    {\n        float _8137 = float(k & 1);\n        float _8141 = float((k >> 1) & 1);\n        float _8145 = float((k >> 2) & 1);\n        if (_8137 > 0.5)\n        {\n            _8151 = _8045.x;\n        }\n        else\n        {\n            _8151 = 1.0 - _8045.x;\n        }\n        if (_8141 > 0.5)\n        {\n            _8164 = _8045.y;\n        }\n        else\n        {\n            _8164 = 1.0 - _8045.y;\n        }\n        if (_8145 > 0.5)\n        {\n            _8178 = _8045.z;\n        }\n        else\n        {\n            _8178 = 1.0 - _8045.z;\n        }\n        float _8188 = (_8151 * _8164) * _8178;\n        if (!(_8188 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8201 = min(_8041 + vec3(_8137, _8141, _8145), _8032);\n        int _8221 = int(((_7965.x + _8201.x) + (_7960.x * (_8201.y + (_7960.y * _8201.z)))) + 0.5);\n        vec2 _8236 = vec2(float(_8221 % _8061) * 10.0, 1024.0 + (float(_8221 / _8061) * 11.0));\n        vec2 param_4 = _8236 + vec2(9.5, 10.5);\n        vec4 _8244 = fa_gi_fetch(param_4);\n        bool _8247 = _8244.y < 0.5;\n        bool _8256;\n        if (!_8247)\n        {\n            _8256 = _8244.x > _7970.y;\n        }\n        else\n        {\n            _8256 = _8247;\n        }\n        if (_8256)\n        {\n            continue;\n        }\n        vec3 _8268 = _8056 - (_7995 + (_8201 * _7988));\n        float _8271 = length(_8268);\n        vec3 _8277 = _8268 / vec3(max(_8271, 9.9999997473787516355514526367188e-05));\n        float _8287 = max(9.9999997473787516355514526367188e-05, (dot(-_8277, n) + 1.0) * 0.5);\n        float w = _8188 * (_8287 * _8287);\n        vec3 param_5 = _8277;\n        vec2 param_6 = (_8236 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8306 = fa_gi_fetch(param_6);\n        float _8313 = _8271 / max(_7965.z, 9.9999997473787516355514526367188e-05);\n        float _8316 = _8306.x;\n        if (_8313 > _8316)\n        {\n            float _8329 = max(_8306.y - (_8316 * _8316), 0.0);\n            float _8334 = _8313 - _8316;\n            float _8343 = _8329 / max(_8329 + (_8334 * _8334), 9.9999999600419720025001879548654e-13);\n            w *= ((_8343 * _8343) * _8343);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8236 + vec2(0.5, 10.5);\n        vec2 param_8 = _8236 + vec2(1.5, 10.5);\n        vec2 param_9 = _8236 + vec2(2.5, 10.5);\n        vec2 param_10 = _8236 + vec2(3.5, 10.5);\n        vec2 param_11 = _8236 + vec2(4.5, 10.5);\n        vec2 param_12 = _8236 + vec2(5.5, 10.5);\n        vec2 param_13 = _8236 + vec2(6.5, 10.5);\n        vec2 param_14 = _8236 + vec2(7.5, 10.5);\n        vec2 param_15 = _8236 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8066)) + (fa_gi_fetch(param_9).xyz * _8070)) + (fa_gi_fetch(param_10).xyz * _8074)) + (fa_gi_fetch(param_11).xyz * _8081)) + (fa_gi_fetch(param_12).xyz * _8088)) + (fa_gi_fetch(param_13).xyz * _8097)) + (fa_gi_fetch(param_14).xyz * _8104)) + (fa_gi_fetch(param_15).xyz * _8117)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8017 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8467;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8467 = _7970.x;\n    }\n    else\n    {\n        _8467 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7965.w * _8467);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8491 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8496 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8501 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8501) && (k < 8); k++)\n    {\n        int param = _8496 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8491;\n        vec3 _8526 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8531 = param_3 * left;\n        acc += (_8526 * _8531);\n        left -= _8531;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8560 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8560;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8602 = vec4(fa_world_pos, 1.0);\n        vec2 _8621 = vec2(dot(fa_mesh_fs_params[26], _8602), dot(fa_mesh_fs_params[27], _8602)) / vec2(max(dot(fa_mesh_fs_params[28], _8602), 9.9999997473787516355514526367188e-05));\n        float _8630;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8630 = (_8621.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8630 = 0.5 - (_8621.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8621.x * 0.5) + 0.5, _8630) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6457;\n    if (fa_lm.z > 0.5)\n    {\n        _6457 = 0.0;\n    }\n    else\n    {\n        _6457 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6468 = _6457 < 1.0;\n    bool _6474;\n    if (_6468)\n    {\n        int param = li;\n        _6474 = fa_light_baked(param);\n    }\n    else\n    {\n        _6474 = _6468;\n    }\n    return _6474 ? _6457 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _884 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _897 = (c - (ru * hx)) - p;\n        vec3 _903 = ru * (2.0 * hx);\n        float _909 = max(dot(_903, _903), 9.9999999392252902907785028219223e-09);\n        float _913 = dot(_897, _903);\n        float t = clamp((-_913) / _909, 0.0, 1.0);\n        if (_884)\n        {\n            float _928 = dot(r, _903);\n            float _934 = _909 - (_928 * _928);\n            if (abs(_934) > (9.9999997473787516355514526367188e-06 * _909))\n            {\n                t = clamp(((dot(r, _897) * _928) - _913) / _934, 0.0, 1.0);\n            }\n        }\n        return (p + _897) + (_903 * t);\n    }\n    vec3 q = p;\n    float _966 = dot(r, axis);\n    bool _974;\n    if (_884)\n    {\n        _974 = abs(_966) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _974 = _884;\n    }\n    if (_974)\n    {\n        float _984 = dot(c - p, axis) / _966;\n        if (_984 > 0.0)\n        {\n            q = p + (r * _984);\n        }\n    }\n    vec3 _997 = q - c;\n    vec2 xy = vec2(dot(_997, ru), dot(_997, uu));\n    if (shape > 0.5)\n    {\n        float _1012 = length(xy);\n        if (_1012 > hx)\n        {\n            xy *= (hx / _1012);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _651 = abs(d);\n    float _653 = _651.x;\n    float _655 = _651.y;\n    bool _656 = _653 >= _655;\n    bool _664;\n    if (_656)\n    {\n        _664 = _653 >= _651.z;\n    }\n    else\n    {\n        _664 = _656;\n    }\n    int _665;\n    if (_664)\n    {\n        _665 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _679;\n        if (_655 >= _651.z)\n        {\n            _679 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _679 = (d.z > 0.0) ? 4 : 5;\n        }\n        _665 = _679;\n    }\n    return _665;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _804 = dot(d, right);\n    float _808 = dot(d, up);\n    float _819;\n    if (((_804 * _804) + (_808 * _808)) > 1.0000000133514319600180897396058e-10)\n    {\n        _819 = atan(_808, _804) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _819 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_819 - floor(_819)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1050 = fa_light_base(param);\n    bool _1054 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1050;\n    vec4 _1058 = fa_light_texel(param_1);\n    int param_2 = _1050 + 1;\n    vec4 _1063 = fa_light_texel(param_2);\n    float _1066 = _1063.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1078 = _1054 && (_1066 > 2.5);\n    fa_light_is_area = _1078;\n    bool _1080 = _1066 < 0.5;\n    vec3 l;\n    if (_1080)\n    {\n        l = normalize(_1058.xyz);\n        if (_1054)\n        {\n            int param_3 = _1050 + 6;\n            vec4 _1094 = fa_light_texel(param_3);\n            if (_1094.z > 0.5)\n            {\n                int param_4 = _1050 + 4;\n                vec4 _1104 = fa_light_texel(param_4);\n                int param_5 = _1050 + 5;\n                vec4 _1109 = fa_light_texel(param_5);\n                vec2 param_6 = _1094.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1104.xyz) * _1104.w, (-dot(world_pos, _1109.xyz)) * _1109.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1139 = _1058.xyz;\n        vec3 _1141 = _1139 - world_pos;\n        vec3 to_light = _1141;\n        float _1144 = length(_1141);\n        float reach = _1144;\n        bool front = true;\n        if (_1078)\n        {\n            int param_8 = _1050 + 7;\n            reach = max(_1144 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1050 + 4;\n            vec4 _1168 = fa_light_texel(param_9);\n            int param_10 = _1050 + 5;\n            vec4 _1173 = fa_light_texel(param_10);\n            int param_11 = _1050 + 6;\n            vec4 _1178 = fa_light_texel(param_11);\n            float _1179 = _1178.w;\n            int param_12 = _1050 + 2;\n            vec3 _1186 = normalize(fa_light_texel(param_12).xyz);\n            bool _1188 = _1179 > 1.5;\n            bool _1196;\n            if (!_1188)\n            {\n                _1196 = dot(_1186, to_light) < 0.0;\n            }\n            else\n            {\n                _1196 = _1188;\n            }\n            front = _1196;\n            vec3 r = vec3(0.0);\n            vec3 _1205 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1209 = dot(n, n) > 0.5;\n            bool _1217;\n            if (_1209)\n            {\n                _1217 = dot(_1205, _1205) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1217 = _1209;\n            }\n            if (_1217)\n            {\n                r = reflect(-normalize(_1205), normalize(n));\n            }\n            vec3 param_13 = _1139;\n            vec3 param_14 = _1186;\n            vec3 param_15 = _1168.xyz;\n            vec3 param_16 = _1173.xyz;\n            float param_17 = _1168.w;\n            float param_18 = _1173.w;\n            float param_19 = _1179;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1253 = length(to_light);\n        dist = _1253;\n        l = to_light / vec3(max(_1253, 9.9999997473787516355514526367188e-05));\n        float _1267 = reach / max(_1058.w, 0.001000000047497451305389404296875);\n        float _1273 = clamp(1.0 - (_1267 * _1267), 0.0, 1.0);\n        float _1275;\n        if (front)\n        {\n            _1275 = _1273 * _1273;\n        }\n        else\n        {\n            _1275 = 0.0;\n        }\n        atten = _1275;\n        bool _1286 = _1066 < 2.5;\n        if ((_1066 > 1.5) && _1286)\n        {\n            int param_22 = _1050 + 2;\n            vec4 _1294 = fa_light_texel(param_22);\n            float _1304 = _1294.w;\n            int param_23 = _1050 + 3;\n            vec4 _1309 = fa_light_texel(param_23);\n            float _1310 = _1309.x;\n            float cos_inner = _1310;\n            if (_1310 > 1.5)\n            {\n                cos_inner = mix(_1304, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1304, cos_inner, dot(-l, normalize(_1294.xyz)));\n        }\n        if (_1054 && (_1066 < 1.5))\n        {\n            int param_24 = _1050 + 6;\n            vec4 _1334 = fa_light_texel(param_24);\n            if (_1334.z > 0.5)\n            {\n                vec3 _1342 = -to_light;\n                int param_25 = _1050 + 4;\n                int param_26 = _1050 + 5;\n                vec3 _1356 = fa_light_texel(param_25).xyz;\n                vec3 _1360 = fa_light_texel(param_26).xyz;\n                vec3 _1369 = vec3(dot(_1342, _1356), dot(_1342, _1360), dot(_1342, cross(_1356, _1360)));\n                vec3 param_27 = _1369;\n                int _1373 = fa_cube_face(param_27);\n                int param_28 = _1373;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1400 = vec2(dot(_1369, cross(param_29, param_30)), dot(_1369, param_30)) / vec2(max(dot(_1369, param_29), 9.9999997473787516355514526367188e-05));\n                int _1404 = _1373 / 3;\n                vec2 param_31 = _1334.xy + (vec2(float(_1373 - (_1404 * 3)), float(_1404)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1400.x), 0.5 - (0.5 * _1400.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1050 + 7;\n            vec4 _1434 = fa_light_texel(param_33);\n            if (_1434.z > 0.5)\n            {\n                int param_34 = _1050 + 2;\n                int param_35 = _1050 + 4;\n                int param_36 = _1050 + 5;\n                vec2 param_37 = _1434.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1054 && _1286)\n            {\n                int param_42 = _1050 + 6;\n                vec4 _1481 = fa_light_texel(param_42);\n                int param_43 = _1050 + 7;\n                vec4 _1486 = fa_light_texel(param_43);\n                bool _1489 = _1481.z > 0.5;\n                bool _1496;\n                if (!_1489)\n                {\n                    _1496 = _1486.z > 0.5;\n                }\n                else\n                {\n                    _1496 = _1489;\n                }\n                if (_1496)\n                {\n                    int param_44 = _1050 + 2;\n                    vec4 _1503 = fa_light_texel(param_44);\n                    vec3 _1507 = normalize(_1503.xyz);\n                    int param_45 = _1050 + 4;\n                    vec4 _1512 = fa_light_texel(param_45);\n                    int param_46 = _1050 + 5;\n                    vec4 _1517 = fa_light_texel(param_46);\n                    if (_1489)\n                    {\n                        vec3 _1525 = -to_light;\n                        float _1532 = _1503.w;\n                        float _1548 = 0.5 / max(dot(_1525, _1507) * (sqrt(max(1.0 - (_1532 * _1532), 0.0)) / max(_1532, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1481.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1525, _1512.xyz) * _1548), 0.5 - (dot(_1525, _1517.xyz) * _1548));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1486.z > 0.5)\n                    {\n                        vec2 param_49 = _1486.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1507;\n                        vec3 param_52 = _1512.xyz;\n                        vec3 param_53 = _1517.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9729 = _1063.xyz * atten;\n    if (_1054)\n    {\n        _9729 *= fa_light_tint;\n    }\n    int _1617;\n    if (_1080)\n    {\n        _1617 = 0;\n    }\n    else\n    {\n        _1617 = ((_1066 > 1.5) && (_1066 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9729, atten, 1.0, dist, _1617);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2343;\n    if (i == 0)\n    {\n        _2343 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2359;\n        if (i == 1)\n        {\n            _2359 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2367;\n            if (i == 2)\n            {\n                _2367 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2367 = fa_shadows[24].w;\n            }\n            _2359 = _2367;\n        }\n        _2343 = _2359;\n    }\n    return _2343;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2400 = fa_shadow_depth(param, param_1);\n    float _2404;\n    if (conv.x < 0.5)\n    {\n        _2404 = _2400;\n    }\n    else\n    {\n        _2404 = (conv.y * conv.z) / (conv.z - (_2400 * (conv.z - conv.y)));\n    }\n    return _2404;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2450 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2456 = vec2(cos(_2450), sin(_2450));\n    vec2 dir = _2456;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2465;\n        if (k < 0.0)\n        {\n            _2465 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2465 = k;\n        }\n        float _2484 = clamp((_2465 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2503 = sqrt((float(i) + 0.5) * 0.0625) * _2484;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2503));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2517 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2517 < (zr - (_2503 * plane)))\n            {\n                sum += _2517;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2545 = sum / cnt;\n        float _2555;\n        if (k < 0.0)\n        {\n            _2555 = (-k) / max(_2545, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2555 = k;\n        }\n        radius = clamp(((max(zr - _2545, 0.0) * unit) * _2555) / texel_m, 1.5, 16.0);\n        dir = _2456;\n    }\n    float lit = 0.0;\n    int _2581 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2581; i_1++)\n    {\n        float _2600 = sqrt((float(i_1) + 0.5) / float(_2581)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2600));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2600 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2581);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2646 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2651 = clamp(dot(n, l), 0.0, 1.0);\n    float _2657 = sqrt(1.0 - (_2651 * _2651));\n    float _2665 = min(_2657 / max(_2651, 0.20000000298023223876953125), 4.0);\n    float _2670;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2670 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2670 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2695 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2670 * _2657)), 1.0);\n    float _2702 = _2695.x;\n    bool _2705 = _2702 < fa_shadows[ci * 1 + 16].x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2695.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2695.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    bool _2739;\n    if (!_2732)\n    {\n        _2739 = _2695.z > 1.0;\n    }\n    else\n    {\n        _2739 = _2732;\n    }\n    if (_2739)\n    {\n        return -1.0;\n    }\n    float _2747;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2747 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2747 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2695.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2695.z - ((_2747 * (1.0 + (0.5 * _2665))) / _2646);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2646;\n    float param_5 = _2646 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2665, 3.0)) * 0.5) / _2646;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3125 = int(fa_shadows[25].x + 0.5);\n    if (_3125 < 1)\n    {\n        return 1.0;\n    }\n    float _3140 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3125 - 1;\n    if (_3140 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3152 = _3125 > 1;\n    bool _3159;\n    if (_3152)\n    {\n        _3159 = _3140 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3159 = _3152;\n    }\n    if (_3159)\n    {\n        ci = 1;\n    }\n    bool _3163 = _3125 > 2;\n    bool _3170;\n    if (_3163)\n    {\n        _3170 = _3140 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3170 = _3163;\n    }\n    if (_3170)\n    {\n        ci = 2;\n    }\n    bool _3174 = _3125 > 3;\n    bool _3181;\n    if (_3174)\n    {\n        _3181 = _3140 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3181 = _3174;\n    }\n    if (_3181)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3192 = min(_3125, 4);\n    float _3233;\n    for (int c = ci; c < _3192; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3212 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3212;\n            break;\n        }\n        if (_3212 < 0.0)\n        {\n            continue;\n        }\n        s = _3212;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3233 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3233 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3252 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3233, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3140 - (fa_shadow_split_at(param_7) - _3252)) / _3252, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3284;\n        if ((ci + 1) < _3125)\n        {\n            _3284 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3284 = 1.0;\n        }\n        s = mix(s, _3284, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3389 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3395;\n    if (_3389)\n    {\n        _3395 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3395 = _3389;\n    }\n    if (_3395)\n    {\n        float _3409 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3412 = fwidth(_3409);\n        vec4 _3422 = vec4(fa_world_pos, 1.0);\n        float _3428 = dot(fa_mesh_fs_params[28], _3422);\n        if (_3428 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3447 = vec2(dot(fa_mesh_fs_params[26], _3422), dot(fa_mesh_fs_params[27], _3422)) / vec2(_3428);\n            float _3452 = (_3447.x * 0.5) + 0.5;\n            float _3456;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3456 = (_3447.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3456 = 0.5 - (_3447.y * 0.5);\n            }\n            bool _3472 = _3452 >= 0.0;\n            bool _3478;\n            if (_3472)\n            {\n                _3478 = _3452 < 1.0;\n            }\n            else\n            {\n                _3478 = _3472;\n            }\n            bool _3484;\n            if (_3478)\n            {\n                _3484 = _3456 >= 0.0;\n            }\n            else\n            {\n                _3484 = _3478;\n            }\n            bool _3490;\n            if (_3484)\n            {\n                _3490 = _3456 < 1.0;\n            }\n            else\n            {\n                _3490 = _3484;\n            }\n            if (_3490)\n            {\n                vec4 _3516 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3452, _3456) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3519 = _3516.w > 0.5;\n                bool _3535;\n                if (_3519)\n                {\n                    _3535 = abs(_3409 - _3516.x) <= (((0.00200000009499490261077880859375 * _3409) + 0.00999999977648258209228515625) + min(1.5 * _3412, 0.100000001490116119384765625 * _3409));\n                }\n                else\n                {\n                    _3535 = _3519;\n                }\n                if (_3535)\n                {\n                    float _3541;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3541 = min(_3516.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3541 = _3516.y;\n                    }\n                    return _3541;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2805 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2812;\n    if (!_2805)\n    {\n        _2812 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2812 = _2805;\n    }\n    if (_2812)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2825 = fa_light_texel(param);\n    float _2826 = _2825.x;\n    if (_2826 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2835 = int(_2826 + 0.5);\n    int param_1 = _2835;\n    vec4 _2839 = fa_light_texel(param_1);\n    int param_2 = _2835 + 1;\n    vec4 _2844 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2847 = _2839.y;\n    if (_2847 > 0.0)\n    {\n        float _2864 = 1.0 - smoothstep(0.75 * _2847, _2847, length(world - fa_shadows[27].xyz));\n        fade = _2864;\n        if (_2864 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2839.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2888 = (_2835 + 2) + (face * 6);\n    int param_4 = _2888;\n    int param_5 = _2888 + 1;\n    int param_6 = _2888 + 3;\n    vec4 _2902 = fa_light_texel(param_6);\n    int param_7 = _2888 + 4;\n    vec4 _2907 = fa_light_texel(param_7);\n    int param_8 = _2888 + 5;\n    vec4 _2912 = fa_light_texel(param_8);\n    float _2924 = _2912.x * max(dot(_2902, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2929 = clamp(dot(n, l), 0.0, 1.0);\n    float _2952 = clamp(dot(n, _2902.xyz), -1.0, 1.0);\n    float _2971 = min(sqrt(1.0 - (_2952 * _2952)) / max(abs(dot(n, world - lpos)) / max(dot(_2902, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2974 = _2844.y;\n    float _2976;\n    if (_2974 > 0.0)\n    {\n        _2976 = _2974;\n    }\n    else\n    {\n        _2976 = 1.5 * _2924;\n    }\n    vec4 _2996 = vec4(world + (n * (_2976 * sqrt(1.0 - (_2929 * _2929)))), 1.0);\n    float _3000 = dot(_2902, _2996);\n    float _3003 = _2912.y;\n    if (_3000 < _3003)\n    {\n        return 1.0;\n    }\n    vec2 _3018 = vec2(dot(fa_light_texel(param_4), _2996), dot(fa_light_texel(param_5), _2996)) / vec2(_3000);\n    float _3020 = _3018.x;\n    bool _3023 = _3020 < _2907.x;\n    bool _3032;\n    if (!_3023)\n    {\n        _3032 = _3020 > _2907.z;\n    }\n    else\n    {\n        _3032 = _3023;\n    }\n    bool _3041;\n    if (!_3032)\n    {\n        _3041 = _3018.y < _2907.y;\n    }\n    else\n    {\n        _3041 = _3032;\n    }\n    bool _3050;\n    if (!_3041)\n    {\n        _3050 = _3018.y > _2907.w;\n    }\n    else\n    {\n        _3050 = _3041;\n    }\n    if (_3050)\n    {\n        return 1.0;\n    }\n    float _3056 = _2844.x;\n    float _3058;\n    if (_3056 > 0.0)\n    {\n        _3058 = _3056;\n    }\n    else\n    {\n        _3058 = 1.5 * _2924;\n    }\n    vec2 param_9 = _3018;\n    vec4 param_10 = _2907;\n    float param_11 = _3000 - (_3058 * (1.0 + (0.5 * _2971)));\n    float param_12 = _2924;\n    float param_13 = 1.0;\n    float param_14 = _2912.z * 0.25;\n    float param_15 = (_2924 * min(_2971, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _3003, _2912.z);\n    int param_17 = int(_2839.z + 0.5);\n    float param_18 = _2839.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3570 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3576;\n    if (_3570)\n    {\n        _3576 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3576 = _3570;\n    }\n    bool _3582;\n    if (_3576)\n    {\n        _3582 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3582 = _3576;\n    }\n    if (_3582)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3594 = fa_light_texel(param);\n        float _3595 = _3594.z;\n        if (_3595 > 0.5)\n        {\n            float _3608 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3611 = fwidth(_3608);\n            float _3615 = min(1.5 * _3611, 0.100000001490116119384765625 * _3608);\n            vec4 _3621 = vec4(world, 1.0);\n            float _3626 = dot(fa_mesh_fs_params[28], _3621);\n            if (_3626 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3643 = vec2(dot(fa_mesh_fs_params[26], _3621), dot(fa_mesh_fs_params[27], _3621)) / vec2(_3626);\n                float _3648 = (_3643.x * 0.5) + 0.5;\n                float _3652;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3652 = (_3643.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3652 = 0.5 - (_3643.y * 0.5);\n                }\n                bool _3668 = _3648 >= 0.0;\n                bool _3674;\n                if (_3668)\n                {\n                    _3674 = _3648 < 1.0;\n                }\n                else\n                {\n                    _3674 = _3668;\n                }\n                bool _3680;\n                if (_3674)\n                {\n                    _3680 = _3652 >= 0.0;\n                }\n                else\n                {\n                    _3680 = _3674;\n                }\n                bool _3686;\n                if (_3680)\n                {\n                    _3686 = _3652 < 1.0;\n                }\n                else\n                {\n                    _3686 = _3680;\n                }\n                if (_3686)\n                {\n                    ivec2 _3703 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3704 = clamp(ivec2(vec2(_3648, _3652) * fa_mesh_fs_params[24].zw), ivec2(0), _3703);\n                    ivec2 _3716;\n                    ivec2 _3722;\n                    ivec2 _3729;\n                    float _3780;\n                    float _3801;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3716 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3722 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3729 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3740 = bvec2(k == 3);\n                                    _3729 = ivec2(_3740.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3740.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3722 = _3729;\n                            }\n                            _3716 = _3722;\n                        }\n                        vec4 _3757 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3704 + _3716, ivec2(0), _3703), 0);\n                        bool _3760 = _3757.w > 0.5;\n                        bool _3774;\n                        if (_3760)\n                        {\n                            _3774 = abs(_3608 - _3757.x) <= (((0.00200000009499490261077880859375 * _3608) + 0.00999999977648258209228515625) + _3615);\n                        }\n                        else\n                        {\n                            _3774 = _3760;\n                        }\n                        if (_3774)\n                        {\n                            if (_3595 < 1.5)\n                            {\n                                _3780 = 1.0;\n                            }\n                            else\n                            {\n                                _3780 = (_3595 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3797 = mod(floor(_3757.z / _3780), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3801 = min(_3797, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3801 = _3797;\n                            }\n                            return _3801;\n                        }\n                    }\n                }\n            }\n            float _3826;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3826 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3826 = 1.0;\n            }\n            return _3826;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5671 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5678;\n    if (!_5671)\n    {\n        _5678 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5678 = _5671;\n    }\n    if (_5678)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5691 = fa_light_texel(param);\n    float _5692 = _5691.y;\n    float len = _5692;\n    if (_5692 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5704 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5713 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5704);\n    if (_5713 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5719 = len;\n    float _5722 = min(_5719, 0.89999997615814208984375 * dist);\n    len = _5722;\n    float _5727 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5704);\n    float _5732 = _5727 + (0.5 * _5722);\n    vec3 _5738 = world + (gn * _5727);\n    float _5740 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5801;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5755 = (float(k) + _5740) * 0.083333335816860198974609375;\n        vec3 _5763 = _5738 + (l * (_5755 * len));\n        vec4 _5769 = vec4(_5763, 1.0);\n        float _5774 = dot(fa_mesh_fs_params[28], _5769);\n        if (_5774 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5792 = vec2(dot(fa_mesh_fs_params[26], _5769), dot(fa_mesh_fs_params[27], _5769)) / vec2(_5774);\n        float _5796 = _5792.x * 0.5;\n        float _5797 = _5796 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5801 = (_5792.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5801 = 0.5 - (_5792.y * 0.5);\n        }\n        bool _5817 = _5797 < 0.0;\n        bool _5824;\n        if (!_5817)\n        {\n            _5824 = _5797 >= 1.0;\n        }\n        else\n        {\n            _5824 = _5817;\n        }\n        bool _5831;\n        if (!_5824)\n        {\n            _5831 = _5801 < 0.0;\n        }\n        else\n        {\n            _5831 = _5824;\n        }\n        bool _5838;\n        if (!_5831)\n        {\n            _5838 = _5801 >= 1.0;\n        }\n        else\n        {\n            _5838 = _5831;\n        }\n        if (_5838)\n        {\n            break;\n        }\n        vec4 _5862 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5797, _5801) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5862.w < 0.5)\n        {\n            continue;\n        }\n        float _5880 = (dot(fa_mesh_fs_params[29].xyz, _5763) + fa_mesh_fs_params[29].w) - _5862.x;\n        if ((_5880 > _5727) && (_5880 < _5732))\n        {\n            occ = max(occ, (1.0 - (_5755 * _5755)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5797, 0.5 - _5796), min(_5801, 1.0 - _5801))));\n        }\n    }\n    return 1.0 - (occ * _5713);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6513 = fa_baked_keep(param);\n    if (_6513 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6539 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9798 = _6539.color;\n    float _9799 = _6539.attenuation;\n    float _9800 = _6539.shadow;\n    bool _6542 = _6539.type == 0;\n    if (_6542 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6539.direction;\n        float _6553 = fa_shadow_factor(param_5, param_6);\n        _9800 = _6553;\n        _9798 *= _6553;\n    }\n    else\n    {\n        bool _6564 = _6539.type != 0;\n        bool _6570;\n        if (_6564)\n        {\n            _6570 = _9799 > 0.0;\n        }\n        else\n        {\n            _6570 = _6564;\n        }\n        if (_6570)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6539.direction;\n            float _6589 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9800 = _6589;\n            _9798 *= _6589;\n        }\n    }\n    bool _6599 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6605;\n    if (_6599)\n    {\n        _6605 = _9799 > 0.0;\n    }\n    else\n    {\n        _6605 = _6599;\n    }\n    if (_6605)\n    {\n        float _6612;\n        if (_6542)\n        {\n            _6612 = 1000000000.0;\n        }\n        else\n        {\n            _6612 = _6539._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6539.direction;\n        float param_18 = _6612;\n        float _6630 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9800 *= _6630;\n        _9798 *= _6630;\n    }\n    float _6643 = _9799;\n    float _6644 = _6643 * _6513;\n    _9799 = _6644;\n    vec3 _6648 = _9798;\n    vec3 _6649 = _6648 * _6513;\n    _9798 = _6649;\n    return LightSample(_6539.direction, _6649, _6644, _9800, _6539._distance, _6539.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6683 = v - (n * dot(v, n));\n    vec3 t = _6683;\n    float _6687 = dot(_6683, _6683);\n    float l2 = _6687;\n    if (_6687 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6697;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6697 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6697 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6697;\n        l2 = dot(_6697, _6697);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7084;\n    if ((j == 0) || (j == 7))\n    {\n        _7084 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7094;\n        if ((j == 3) || (j == 4))\n        {\n            _7094 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7094 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7084 = _7094;\n    }\n    float _7115;\n    if ((j == 1) || (j == 2))\n    {\n        _7115 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7124;\n        if ((j == 5) || (j == 6))\n        {\n            _7124 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7124 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7115 = _7124;\n    }\n    return (pc + (ex * _7084)) + (ey * _7115);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6732 = dot(a, a);\n    float _6736 = dot(b, b);\n    if ((_6732 < 1.0000000195414813782625560981111e-24) || (_6736 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6750 = a * inversesqrt(_6732);\n    vec3 _6755 = b * inversesqrt(_6736);\n    float _6759 = dot(_6750, _6755);\n    float _6762 = abs(_6759);\n    float g = (((((((((((0.0416471660137176513671875 * _6762) - 0.1924748718738555908203125) * _6762) + 0.4179156124591827392578125) * _6762) - 0.616057217121124267578125) * _6762) + 0.777722418308258056640625) * _6762) - 0.999542415142059326171875) * _6762) + 1.570791721343994140625;\n    if (_6759 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6759 * _6759), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6750, _6755) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6819 = a.z > 0.0;\n    bool _6823 = b.z > 0.0;\n    if (_6819 && _6823)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6819 != _6823)\n        {\n            vec3 _6858 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6858.z = 0.0;\n            if (_6819)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6858;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6858;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6858;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6858;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6907 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6933 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6959 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6985 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6907;\n    vec3 param_1 = _6933;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6933;\n    vec3 param_7 = _6959;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6959;\n    vec3 param_13 = _6985;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6985;\n    vec3 param_19 = _6907;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7153 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7171;\n    for (int k = 0; k < (2 * _7153); k++)\n    {\n        bool _7168 = k >= _7153;\n        if (_7168)\n        {\n            _7171 = k - _7153;\n        }\n        else\n        {\n            _7171 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7153 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7217 = 2 * _7171;\n            int param_4 = _7217 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7217 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7217 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7254 = bvec4(_7168);\n        vec4 param_16 = vec4(_7254.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7254.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7254.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7254.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7265 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7168)\n        {\n            vec2 _10051 = sum;\n            _10051.y = _10051.y + _7265;\n            sum = _10051;\n        }\n        else\n        {\n            vec2 _10054 = sum;\n            _10054.x = _10054.x + _7265;\n            sum = _10054;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7289 = fa_light_base(param);\n    int param_1 = _7289;\n    int param_2 = _7289 + 1;\n    int param_3 = _7289 + 2;\n    int param_4 = _7289 + 4;\n    vec4 _7311 = fa_light_texel(param_4);\n    int param_5 = _7289 + 5;\n    vec4 _7316 = fa_light_texel(param_5);\n    int param_6 = _7289 + 6;\n    vec4 _7321 = fa_light_texel(param_6);\n    float _7322 = _7321.w;\n    vec3 _7327 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7329 = _7322 < 1.5;\n    bool _7336;\n    if (_7329)\n    {\n        _7336 = dot(normalize(fa_light_texel(param_3).xyz), _7327) >= 0.0;\n    }\n    else\n    {\n        _7336 = _7329;\n    }\n    if (_7336)\n    {\n        return vec3(0.0);\n    }\n    bool _7345 = (_7322 > 0.5) && _7329;\n    float _7349 = _7345 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7352 = _7311.xyz;\n    float _7354 = _7311.w;\n    vec3 _7360 = _7316.xyz;\n    float _7362 = _7316.w;\n    vec3 up = _7360 * (_7362 * _7349);\n    float _7368;\n    if (_7345)\n    {\n        _7368 = (3.1415927410125732421875 * _7354) * _7354;\n    }\n    else\n    {\n        _7368 = (4.0 * _7354) * _7362;\n    }\n    if (_7322 > 1.5)\n    {\n        vec3 _7394 = cross(_7352, -_7327);\n        vec3 perp = _7394;\n        float _7398 = dot(_7394, _7394);\n        vec3 _7401;\n        if (_7398 > 1.0000000133514319600180897396058e-10)\n        {\n            _7401 = perp * inversesqrt(_7398);\n        }\n        else\n        {\n            _7401 = _7360;\n        }\n        perp = _7401;\n        up = _7401 * _7362;\n    }\n    float _7422 = max(_7368, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7432 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7432;\n    vec3 param_10 = n;\n    vec3 param_11 = _7327;\n    vec3 param_12 = _7432;\n    vec3 param_13 = n;\n    vec3 param_14 = _7352 * (_7354 * _7349);\n    vec3 param_15 = _7432;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7463 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7463;\n    vec2 param_21 = _7463 + vec2(64.0, 0.0);\n    vec4 _7473 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7322;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7485 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7485.x) + (((f0 * _7473.x) + ((vec3(f90) - f0) * _7473.y)) * _7485.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7327, _7327)) + _7422) / _7422) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5408 = 1.0 / alpha;\n    return ((2.0 + _5408) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5408)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5443 = max(dot(L.nc, l), 0.0);\n    float _5449 = max(dot(L.nc, h), 0.0);\n    float _5458 = ((_5449 * _5449) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5458) * _5458)) * (0.5 / max(mix((2.0 * _5443) * L.coat_ndv, _5443 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5443)) * _5443;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7522;\n    if (L.sheen_on)\n    {\n        _7522 = L.sheen_scale;\n    }\n    else\n    {\n        _7522 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7522);\n    vec3 _7535 = normalize(l + v);\n    int param = li;\n    vec3 _7546 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7555 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7535), 0.0);\n        float param_3 = _7555;\n        float param_4 = ndv;\n        result += ((L.sheen * _7546) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7555)) * _7555) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7535;\n        float param_8 = max(dot(v, _7535), 0.0);\n        result += (_7546 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5311 = tdh / at;\n    float _5315 = bdh / ab;\n    float _5327 = ((_5311 * _5311) + (_5315 * _5315)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5327) * _5327);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5507 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5586 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5586) * _5586);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5507);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5507));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4710 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4713 = _4710.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4713 * _4713, exp2((-9.27999973297119140625) * ndv)) * _4713) + _4710.y)) + _4710.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4020;\n    if (lv == 0)\n    {\n        _4020 = 0.0;\n    }\n    else\n    {\n        _4020 = res + 2.0;\n    }\n    float _4030;\n    if (lv == 0)\n    {\n        _4030 = 0.0;\n    }\n    else\n    {\n        _4030 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4020, _4030)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4076;\n    if (res > 64.5)\n    {\n        _4076 = 5.0;\n    }\n    else\n    {\n        _4076 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4091 = clamp(rough, 0.0, 1.0) * (_4076 - 1.0);\n    int _4098 = int(min(floor(_4091), _4076 - 2.0));\n    float _4103 = _4091 - float(_4098);\n    vec3 param = d;\n    vec2 _4107 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4098;\n    vec2 param_4 = _4107;\n    vec3 _4117 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4103 < 0.00200000009499490261077880859375)\n    {\n        return _4117;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4098 + 1;\n    vec2 param_8 = _4107;\n    return mix(_4117, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4103));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4188 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4195 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4202 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4208 = dot(bx.xyz, d);\n    float _4212 = dot(by.xyz, d);\n    float _4216 = dot(bz.xyz, d);\n    float _4222;\n    if (_4208 > 9.9999999747524270787835121154785e-07)\n    {\n        _4222 = (1.0 - _4188) / _4208;\n    }\n    else\n    {\n        float _4236;\n        if (_4208 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4236 = ((-1.0) - _4188) / _4208;\n        }\n        else\n        {\n            _4236 = 1000000015047466219876688855040.0;\n        }\n        _4222 = _4236;\n    }\n    float tx = _4222;\n    float _4253;\n    if (_4212 > 9.9999999747524270787835121154785e-07)\n    {\n        _4253 = (1.0 - _4195) / _4212;\n    }\n    else\n    {\n        float _4266;\n        if (_4212 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4266 = ((-1.0) - _4195) / _4212;\n        }\n        else\n        {\n            _4266 = 1000000015047466219876688855040.0;\n        }\n        _4253 = _4266;\n    }\n    float ty = _4253;\n    float _4282;\n    if (_4216 > 9.9999999747524270787835121154785e-07)\n    {\n        _4282 = (1.0 - _4202) / _4216;\n    }\n    else\n    {\n        float _4295;\n        if (_4216 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4295 = ((-1.0) - _4202) / _4216;\n        }\n        else\n        {\n            _4295 = 1000000015047466219876688855040.0;\n        }\n        _4282 = _4295;\n    }\n    float _4307 = tx;\n    float _4310 = (_4307 > 0.0) ? _4307 : 1000000015047466219876688855040.0;\n    tx = _4310;\n    float _4311 = ty;\n    float _4314 = (_4311 > 0.0) ? _4311 : 1000000015047466219876688855040.0;\n    ty = _4314;\n    float _4324 = min(_4310, min(_4314, (_4282 > 0.0) ? _4282 : 1000000015047466219876688855040.0));\n    if (_4324 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4340 = (fa_world_pos + (d * _4324)) - posw.xyz;\n    vec3 _4345;\n    if (dot(_4340, _4340) > 1.0000000133514319600180897396058e-10)\n    {\n        _4345 = normalize(_4340);\n    }\n    else\n    {\n        _4345 = d;\n    }\n    return _4345;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4391 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4391 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4419 = rough * rough;\n            float _4450 = 0.60000002384185791015625 * _4419;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4419)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4450, 0.0500000007450580596923828125 + _4450, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4419 * 0.60000002384185791015625));\n        }\n        outc = base * _4391;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4509 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4509 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4541 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4541 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5188;\n        if (L.aniso >= 0.0)\n        {\n            _5188 = L.b;\n        }\n        else\n        {\n            _5188 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5188, v), _5188), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5224 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5224.x) + (vec3(L.f90) * _5224.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5282 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5282.x) + _5282.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4752 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4752.x) + vec3(_4752.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5984 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5988 = fa_xm_origin(param_1);\n    vec2 _5994 = (uv * _5984) - vec2(0.5);\n    vec2 _5997 = fract(_5994);\n    vec2 _6000 = floor(_5994);\n    vec2 param_2 = _5984;\n    vec2 param_3 = _5988;\n    vec2 param_4 = _6000;\n    vec2 param_5 = _5984;\n    vec2 param_6 = _5988;\n    vec2 param_7 = _6000 + vec2(1.0, 0.0);\n    vec2 param_8 = _5984;\n    vec2 param_9 = _5988;\n    vec2 param_10 = _6000 + vec2(0.0, 1.0);\n    vec2 param_11 = _5984;\n    vec2 param_12 = _5988;\n    vec2 param_13 = _6000 + vec2(1.0);\n    vec3 _6042 = vec3(_5997.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6042), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6042), vec3(_5997.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6061 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6065 = clamp(lod, 0.0, _6061);\n    int _6069 = int(floor(_6065));\n    int param = _6069;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6079 = float(_6069);\n    float _6080 = _6065 - _6079;\n    bool _6082 = _6080 > 0.001000000047497451305389404296875;\n    bool _6089;\n    if (_6082)\n    {\n        _6089 = _6079 < _6061;\n    }\n    else\n    {\n        _6089 = _6082;\n    }\n    if (_6089)\n    {\n        int param_2 = _6069 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6080));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6115 = fa_env_brdf(param, param_1);\n    vec3 _6139 = ((vec3(1.0) - clamp((f0 * _6115.x) + (vec3(f90) * _6115.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6139;\n    float _6145 = max(s.thickness, 0.0);\n    bool _6150 = _6145 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6150)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6145);\n    }\n    bool _6175 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6181;\n    if (_6175)\n    {\n        _6181 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6181 = _6175;\n    }\n    bool _6188;\n    if (!_6181)\n    {\n        _6188 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6188 = _6181;\n    }\n    if (_6188)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6203 = vec4(fa_world_pos, 1.0);\n    float _6208 = dot(fa_mesh_fs_params[28], _6203);\n    vec2 uv0 = vec2(0.5);\n    if (_6208 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6226 = vec2(dot(fa_mesh_fs_params[26], _6203), dot(fa_mesh_fs_params[27], _6203)) / vec2(_6208);\n        float _6234;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6234 = (_6226.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6234 = 0.5 - (_6226.y * 0.5);\n        }\n        uv0 = vec2((_6226.x * 0.5) + 0.5, _6234);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6255 = fa_xm_size(param_2);\n        vec2 _6263 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6255);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6263), 0).w > 0.5)\n        {\n            int _6283 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6306 = abs(dx) > _6283;\n                    bool _6314;\n                    if (!_6306)\n                    {\n                        _6314 = abs(dy) > _6283;\n                    }\n                    else\n                    {\n                        _6314 = _6306;\n                    }\n                    if (_6314)\n                    {\n                        continue;\n                    }\n                    vec4 _6335 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6263 + vec2(float(dx), float(dy)), vec2(0.0), _6255 - vec2(1.0))), 0);\n                    if (_6335.w > 0.5)\n                    {\n                        acc += _6335.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6139 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6150)\n    {\n        vec4 _6383 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6145), 1.0);\n        float _6388 = dot(fa_mesh_fs_params[28], _6383);\n        uv = vec2(0.5);\n        if (_6388 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6405 = vec2(dot(fa_mesh_fs_params[26], _6383), dot(fa_mesh_fs_params[27], _6383)) / vec2(_6388);\n            float _6413;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6413 = (_6405.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6413 = 0.5 - (_6405.y * 0.5);\n            }\n            uv = vec2((_6405.x * 0.5) + 0.5, _6413);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3312 = int(fa_shadows[25].x + 0.5);\n    float _3322 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3327 = _3312 > 0;\n    bool _3336;\n    if (_3327)\n    {\n        int param = _3312 - 1;\n        _3336 = _3322 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3336 = _3327;\n    }\n    if (_3336)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3342 = _3312 > 1;\n        bool _3349;\n        if (_3342)\n        {\n            _3349 = _3322 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3349 = _3342;\n        }\n        if (_3349)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3355 = _3312 > 2;\n        bool _3362;\n        if (_3355)\n        {\n            _3362 = _3322 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3362 = _3355;\n        }\n        if (_3362)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3368 = _3312 > 3;\n        bool _3375;\n        if (_3368)\n        {\n            _3375 = _3322 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3375 = _3368;\n        }\n        if (_3375)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _9457 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9457 = -_9457;\n    }\n    vec3 _8743 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9457, fa_world_tangent, fa_uv, fa_vertex_color, _8743, gl_FrontFacing);\n    Surface _8751 = fa_standard_surface(param_1);\n    vec3 _9488 = _8751.albedo;\n    float _9489 = _8751.alpha;\n    vec3 _9490 = _8751.normal;\n    float _9491 = _8751.metallic;\n    float _9492 = _8751.roughness;\n    float _9493 = _8751.occlusion;\n    vec3 _9494 = _8751.emission;\n    float _9495 = _8751.clearcoat;\n    float _9496 = _8751.clearcoat_roughness;\n    vec3 _9497 = _8751.sheen_color;\n    float _9498 = _8751.sheen_roughness;\n    float _9499 = _8751.anisotropy;\n    float _9500 = _8751.anisotropy_rotation;\n    float _9501 = _8751.specular;\n    float _9502 = _8751.ior;\n    vec3 _9503 = _8751.specular_color;\n    float _9504 = _8751.transmission;\n    float _9505 = _8751.thickness;\n    vec3 _9506 = _8751.attenuation_color;\n    float _9507 = _8751.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9457, fa_world_tangent, fa_uv, fa_vertex_color, _8743, gl_FrontFacing);\n    Surface param_3 = _8751;\n    surface(param_2, param_3);\n    _9488 = param_3.albedo;\n    _9489 = param_3.alpha;\n    _9490 = param_3.normal;\n    _9491 = param_3.metallic;\n    _9492 = param_3.roughness;\n    _9493 = param_3.occlusion;\n    _9494 = param_3.emission;\n    _9495 = param_3.clearcoat;\n    _9496 = param_3.clearcoat_roughness;\n    _9497 = param_3.sheen_color;\n    _9498 = param_3.sheen_roughness;\n    _9499 = param_3.anisotropy;\n    _9500 = param_3.anisotropy_rotation;\n    _9501 = param_3.specular;\n    _9502 = param_3.ior;\n    _9503 = param_3.specular_color;\n    _9504 = param_3.transmission;\n    _9505 = param_3.thickness;\n    _9506 = param_3.attenuation_color;\n    _9507 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9457;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9488 = param_6;\n    _9490 = param_7;\n    if (_9489 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9488;\n    }\n    else\n    {\n        vec3 _8803 = normalize(_9490);\n        float _8810 = clamp(_9491, 0.0, 1.0);\n        float _8814 = clamp(_9492, 0.0500000007450580596923828125, 1.0);\n        float _8818 = _8814 * _8814;\n        float _8822 = _8818 * _8818;\n        float _8827 = max(dot(_8803, _8743), 9.9999997473787516355514526367188e-05);\n        float _8833 = 1.0 - _8810;\n        float _8834 = clamp(_9504, 0.0, 1.0) * _8833;\n        vec3 _8843 = (_9488 * _8833) * (1.0 - _8834);\n        vec3 _8850 = mix(vec3(0.039999999105930328369140625), _9488, vec3(_8810));\n        vec3 f0 = _8850;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9457, fa_world_tangent, fa_uv, fa_vertex_color, _8743, gl_FrontFacing);\n        Surface param_9 = Surface(_9488, _9489, _9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, _9498, _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507);\n        vec3 param_10 = _8803;\n        vec3 param_11 = _8743;\n        float param_12 = _8810;\n        float param_13 = _8814;\n        vec3 param_14 = _8850;\n        FaLayers _8866 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8803;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8843) * _9493;\n        if (_8866.on)\n        {\n            lit *= _8866.base_scale;\n        }\n        int _8888 = fa_cl_ndir + fa_cl_local;\n        float _8953;\n        for (int ln = 0; ln < _8888; ln++)\n        {\n            int param_16 = ln;\n            int _8901 = fa_cl_light(param_16);\n            int param_17 = _8901;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8901;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9457;\n            LightSample _8917 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8925 = max(dot(_8803, _8917.direction), 0.0);\n            float _8931 = _8917.attenuation * _8917.shadow;\n            vec3 _8936 = normalize(_8917.direction + _8743);\n            float _8941 = max(dot(_8803, _8936), 0.0);\n            float _8946 = max(dot(_8743, _8936), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8866.on)\n                {\n                    _8953 = _8866.f90;\n                }\n                else\n                {\n                    _8953 = 1.0;\n                }\n                int param_21 = _8901;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8803;\n                vec3 param_24 = _8743;\n                vec3 param_25 = _8843;\n                vec3 param_26 = f0;\n                float param_27 = _8953;\n                float param_28 = _8814;\n                float param_29 = _8827;\n                float param_30 = _8931;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8866.on)\n                {\n                    FaLayers param_31 = _8866;\n                    vec3 param_32 = area;\n                    int param_33 = _8901;\n                    vec3 param_34 = _8803;\n                    vec3 param_35 = _8743;\n                    vec3 param_36 = _8917.direction;\n                    float param_37 = _8827;\n                    float param_38 = _8931;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8866.on)\n                {\n                    FaLayers param_39 = _8866;\n                    vec3 param_40 = _8843;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8803;\n                    vec3 param_43 = _8743;\n                    vec3 param_44 = _8917.direction;\n                    vec3 param_45 = _8936;\n                    float param_46 = _8925;\n                    float param_47 = _8827;\n                    float param_48 = _8941;\n                    float param_49 = _8946;\n                    float param_50 = _8818;\n                    float param_51 = _8822;\n                    int param_52 = _8901;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8931));\n                }\n                else\n                {\n                    float _9055 = ((_8941 * _8941) * (_8822 - 1.0)) + 1.0;\n                    int param_53 = _8901;\n                    lit += (((_8843 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8946, 5.0))) * (((_8822 / ((3.1415927410125732421875 * _9055) * _9055)) * (0.5 / max(mix((2.0 * _8925) * _8827, _8925 + _8827, _8818), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8925))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8925 * _8931));\n                }\n            }\n        }\n        if (_8866.on)\n        {\n            FaLayers param_54 = _8866;\n            vec3 param_55 = _8803;\n            vec3 param_56 = _8743;\n            vec3 param_57 = f0;\n            float param_58 = _8814;\n            float param_59 = _9493;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8803;\n            vec3 param_61 = _8743;\n            vec3 param_62 = f0;\n            float param_63 = _8814;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9493);\n        }\n        if (_8834 > 0.0)\n        {\n            float _9153;\n            if (_8866.on)\n            {\n                _9153 = _8866.f90;\n            }\n            else\n            {\n                _9153 = 1.0;\n            }\n            float _9161;\n            if (_8866.on)\n            {\n                _9161 = _8866.base_scale;\n            }\n            else\n            {\n                _9161 = 1.0;\n            }\n            Surface param_64 = Surface(_9488, _9489, _9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, _9498, _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507);\n            vec3 param_65 = _8803;\n            vec3 param_66 = _8743;\n            float param_67 = _8814;\n            vec3 param_68 = f0;\n            float param_69 = _9153;\n            float param_70 = _9161;\n            float param_71 = _8834;\n            float param_72 = fa_tr_blend;\n            vec3 _9185 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9185;\n        }\n        result = lit;\n    }\n    vec3 _9192 = result;\n    vec3 _9193 = _9192 + _9494;\n    result = _9193;\n    vec3 param_73 = _9193;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9202 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9209;\n    if (!_9202)\n    {\n        _9209 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9209 = _9202;\n    }\n    if (_9209)\n    {\n        vec3 _9218 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9224 = dot(_9218, fa_mesh_fs_params[9].xyz);\n        bool _9228 = fa_mesh_fs_params[9].w > 0.5;\n        float _9229;\n        if (_9228)\n        {\n            _9229 = _9224;\n        }\n        else\n        {\n            _9229 = length(_9218);\n        }\n        float _9241 = _9229 - fa_mesh_fs_params[8].x;\n        if (_9241 > 0.0)\n        {\n            float _9250 = fa_mesh_fs_params[7].w * _9241;\n            float tau = _9250 * _9250;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9266;\n                if (_9228)\n                {\n                    _9266 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9224);\n                }\n                else\n                {\n                    _9266 = fa_mesh_fs_params[0].y;\n                }\n                float _9287 = mix(_9266, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9229, 0.0, 1.0));\n                float _9291 = fa_world_pos.y - _9287;\n                float _9296 = _9287 - fa_mesh_fs_params[8].z;\n                float _9301 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9304 = _9296 <= 0.0;\n                bool _9305 = !_9304;\n                bool _9311;\n                if (_9305)\n                {\n                    _9311 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9311 = _9304;\n                }\n                float _9312;\n                if (_9311)\n                {\n                    _9312 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9312 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9296, 80.0));\n                }\n                bool _9339;\n                if (_9305)\n                {\n                    _9339 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9339 = _9304;\n                }\n                float _9340;\n                if (_9339)\n                {\n                    _9340 = fa_mesh_fs_params[8].y * _9296;\n                }\n                else\n                {\n                    _9340 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9296, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9365 = _9301 <= 0.0;\n                bool _9372;\n                if (!_9365)\n                {\n                    _9372 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9372 = _9365;\n                }\n                float _9373;\n                if (_9372)\n                {\n                    _9373 = fa_mesh_fs_params[8].y * _9301;\n                }\n                else\n                {\n                    _9373 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9301, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9400;\n                if (abs(_9291) < 0.001000000047497451305389404296875)\n                {\n                    _9400 = _9312;\n                }\n                else\n                {\n                    _9400 = (_9373 - _9340) / _9291;\n                }\n                tau += (_9241 * max(_9400, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9436 = 1.0 - fa_tr_blend;\n        result /= vec3(_9436);\n        _9489 *= _9436;\n    }\n    fa_frag_color = vec4(result, _9489);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_609",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2353",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8779",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4853[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1635 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    bool _1650;\n    if (!_1642)\n    {\n        _1650 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1650 = _1642;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    bool _1664;\n    if (!_1657)\n    {\n        _1664 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1664 = _1657;\n    }\n    if (_1664)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1674 = vec4(world_pos, 1.0);\n    float _1680 = dot(fa_mesh_fs_params[16], _1674);\n    if (!(_1680 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1702 = vec2(dot(fa_mesh_fs_params[14], _1674), dot(fa_mesh_fs_params[15], _1674)) / vec2(_1680);\n    int _1706 = int(fa_mesh_fs_params[18].x);\n    int _1710 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1710) + clamp(int(floor(((_1702.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1710 - 1)) * _1706)) + clamp(int(floor(((_1702.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1706 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1786 = fa_cluster_texel(param);\n    return ivec2(int(_1786.x), int(_1786.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6487 = fa_cluster_lookup(param);\n    fa_cl_slot = _6487.x;\n    fa_cl_local = _6487.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7646 = fa_linear_to_srgb(param);\n        c = _7646;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7654 = fa_srgb_to_linear(param_1);\n            c = _7654;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _541;\n    if (i.front_facing)\n    {\n        _541 = i.world_normal;\n    }\n    else\n    {\n        _541 = -i.world_normal;\n    }\n    vec3 _565 = normalize(i.world_tangent.xyz - (_541 * dot(_541, i.world_tangent.xyz)));\n    vec3 _592 = normalize(((_565 * m.x) + ((cross(_541, _565) * i.world_tangent.w) * m.y)) + (_541 * m.z));\n    vec3 _595;\n    if (i.front_facing)\n    {\n        _595 = _592;\n    }\n    else\n    {\n        _595 = -_592;\n    }\n    return _595;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7686 = fa_tex_fix(param_2, param_3);\n    vec4 _10068 = base_t;\n    _10068.x = _7686.x;\n    _10068.y = _7686.y;\n    _10068.z = _7686.z;\n    base_t = _10068;\n    vec4 _7700 = (_10068 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9818 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7734 = fa_tex_fix(param_6, param_7);\n        vec3 _7737 = (_7734 * 2.0) - vec3(1.0);\n        vec2 _7742 = _7737.xy * fa_mesh_fs_params[6].x;\n        vec3 _10076 = _7737;\n        _10076.x = _7742.x;\n        _10076.y = _7742.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10076;\n        _9818 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7772 = fa_tex_fix(param_12, param_13);\n    vec4 _10079 = mrt;\n    _10079.x = _7772.x;\n    _10079.y = _7772.y;\n    _10079.z = _7772.z;\n    mrt = _10079;\n    vec4 _7802 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7802.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7813 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7845 = fa_tex_fix(param_20, param_21);\n    float _9823 = fa_mesh_fs_params[20].x;\n    float _9824 = fa_mesh_fs_params[20].y;\n    float _9827 = fa_mesh_fs_params[20].z;\n    float _9826 = fa_mesh_fs_params[21].w;\n    float _9829 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9823 *= _7813.y;\n            _9824 *= _7813.z;\n            _9826 *= _7802.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9827 *= mrt.x;\n            _9829 *= mrt.w;\n        }\n    }\n    return Surface(_7700.xyz, _7700.w, _9818, clamp(fa_mesh_fs_params[5].x * _7772.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7772.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7813.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7845), _9823, _9824, fa_mesh_fs_params[21].xyz, _9826, _9827, fa_mesh_fs_params[20].w, _9829, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1866 = rect.zw - rect.xy;\n    vec2 _1870 = _1866 * atlas;\n    vec2 _1874 = ddx * _1870;\n    vec2 _1878 = ddy * _1870;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1866), clamp(0.5 * log2(max(max(dot(_1874, _1874), dot(_1878, _1878)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1911 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1918;\n    if (!_1911)\n    {\n        _1918 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1918 = _1911;\n    }\n    if (_1918)\n    {\n        return;\n    }\n    vec3 _1924 = dFdx(world_pos);\n    vec3 _1927 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1931 = fa_cluster_texel(param);\n    int _1935 = int(_1931.w);\n    if (_1935 < 1)\n    {\n        return;\n    }\n    int _1945 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1945;\n    vec4 _1949 = fa_light_texel(param_1);\n    vec2 _1952 = _1949.yz;\n    int _1956 = int(_1949.w);\n    int param_2 = _1945 + 1;\n    vec4 _1961 = fa_light_texel(param_2);\n    float _1962 = _1961.x;\n    int _1968 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1972 = int(_1931.z);\n    vec3 _2237;\n    for (int k = 0; k < _1935; k++)\n    {\n        int _1985 = _1972 + k;\n        int param_3 = _1956 + (_1985 >> 2);\n        int _2002 = (_1945 + 2) + (int(fa_light_texel(param_3)[_1985 & 3]) * 7);\n        int param_4 = _2002 + 6;\n        vec4 _2007 = fa_light_texel(param_4);\n        if (((int(_2007.w + 0.5) >> _1968) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2002;\n        vec4 _2022 = fa_light_texel(param_5);\n        int param_6 = _2002 + 1;\n        vec4 _2027 = fa_light_texel(param_6);\n        int param_7 = _2002 + 2;\n        vec4 _2032 = fa_light_texel(param_7);\n        vec3 _2035 = _2022.xyz;\n        float _2040 = dot(_2035, world_pos) + _2022.w;\n        vec3 _2042 = _2027.xyz;\n        float _2047 = dot(_2042, world_pos) + _2027.w;\n        vec3 _2049 = _2032.xyz;\n        float _2054 = dot(_2049, world_pos) + _2032.w;\n        bool _2059 = abs(_2040) > 0.5;\n        bool _2067;\n        if (!_2059)\n        {\n            _2067 = abs(_2047) > 0.5;\n        }\n        else\n        {\n            _2067 = _2059;\n        }\n        bool _2075;\n        if (!_2067)\n        {\n            _2075 = abs(_2054) > 0.5;\n        }\n        else\n        {\n            _2075 = _2067;\n        }\n        if (_2075)\n        {\n            continue;\n        }\n        float _2090 = clamp(dot(geo_normal, normalize(_2049)) * _2007.z, 0.0, 1.0);\n        if (_2090 <= 0.0)\n        {\n            continue;\n        }\n        float _2110 = (clamp((0.5 - abs(_2054)) * 10.0, 0.0, 1.0) * _2090) * _2007.x;\n        vec2 _2118 = vec2(_2040 + 0.5, 0.5 - _2047);\n        vec2 _2128 = vec2(dot(_2035, _1924), dot(_2042, _1924));\n        vec2 _2138 = vec2(dot(_2035, _1927), dot(_2042, _1927));\n        int param_8 = _2002 + 5;\n        vec4 _2143 = fa_light_texel(param_8);\n        int param_9 = _2002 + 3;\n        vec4 _2148 = fa_light_texel(param_9);\n        int param_10 = _2002 + 4;\n        vec4 _2153 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2143.xyz;\n        bool _2163 = _2148.z > _2148.x;\n        if (_2163)\n        {\n            vec4 param_11 = _2148;\n            vec2 param_12 = _2118;\n            vec2 param_13 = _1952;\n            vec2 param_14 = _2128;\n            vec2 param_15 = _2138;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1962 > 0.5) && (_1962 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2189 = fa_dc_to_linear(param_16);\n                vec4 _9906 = tx;\n                _9906.x = _2189.x;\n                _9906.y = _2189.y;\n                _9906.z = _2189.z;\n                tx = _9906;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2110 * tex_a) * _2143.w, 0.0, 1.0)));\n        if (_2153.z > _2153.x)\n        {\n            vec4 param_17 = _2153;\n            vec2 param_18 = _2118;\n            vec2 param_19 = _1952;\n            vec2 param_20 = _2128;\n            vec2 param_21 = _2138;\n            vec4 _2233 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1962 > 1.5)\n            {\n                vec3 param_22 = _2233.xyz;\n                vec3 _2243 = fa_dc_to_srgb(param_22);\n                _2237 = _2243;\n            }\n            else\n            {\n                _2237 = _2233.xyz;\n            }\n            vec3 _2252 = (_2237 * 2.0) - vec3(1.0);\n            vec2 _2257 = _2252.xy * _2007.y;\n            vec3 _2279 = (normalize(_2035) * _2257.x) + (normalize(_2042) * _2257.y);\n            vec3 _2282 = normalize(normal);\n            normal = normalize(mix(_2282, normalize((_2282 * max(_2252.z, 0.0500000007450580596923828125)) + (_2279 - (_2282 * dot(_2282, _2279)))), vec3(clamp(_2110 * (_2163 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _631 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _634;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _634 = _631 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _634 = _631 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_634)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4778 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4786 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4789 = int(_4778);\n    int _4792 = int(_4786);\n    float _4802 = _4786 - float(_4792);\n    int _4857 = (_4789 * 9) + _4792;\n    int _4877 = ((_4789 + 1) * 9) + _4792;\n    return mix(mix(_4853[_4857], _4853[_4857 + 1], _4802), mix(_4853[_4877], _4853[_4877 + 1], _4802), _4778 - float(_4789));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9741 = false;\n    float _9742 = 1.0;\n    float _9743 = 1.0;\n    float _9744 = 1.0;\n    float _9745 = 0.0;\n    float _9746 = 0.0;\n    float _9747 = 0.0;\n    float _9748 = 0.0;\n    float _9750 = 1.0;\n    bool _9751 = false;\n    vec3 _9752 = vec3(0.0);\n    float _9753 = 1.0;\n    float _9754 = 1.0;\n    float _9755 = 1.0;\n    float _9756 = 0.0;\n    float _9757 = 0.0;\n    vec3 _9758 = vec3(1.0, 0.0, 0.0);\n    vec3 _9759 = vec3(0.0, 0.0, 1.0);\n    float _9760 = 1.0;\n    float _9761 = 1.0;\n    float _4928 = clamp(s.specular, 0.0, 1.0);\n    float _4932 = clamp(s.ior, 1.0, 3.0);\n    bool _4937 = (_4928 != 1.0) || (_4932 != 1.5);\n    bool _4946;\n    if (!_4937)\n    {\n        _4946 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4946 = _4937;\n    }\n    if (_4946)\n    {\n        float _4954 = (_4932 - 1.0) / (_4932 + 1.0);\n        f0 = mix(min(vec3(_4954 * _4954) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4928, s.albedo, vec3(metallic));\n        _9742 = mix(_4928, 1.0, metallic);\n        _9741 = true;\n    }\n    float _4981 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4981 > 0.0)\n    {\n        float _4989 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9745 = _4981;\n        _9746 = _4989;\n        float _4996 = _4989 * _4989;\n        _9747 = _4996;\n        _9748 = _4996 * _4996;\n        float _5008 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9750 = _5008;\n        _9743 = 1.0 - (_4981 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5008, 0.0, 1.0), 5.0))));\n        _9741 = true;\n    }\n    vec3 _5027 = max(s.sheen_color, vec3(0.0));\n    float _5036 = max(_5027.x, max(_5027.y, _5027.z));\n    if (_5036 > 0.0)\n    {\n        float _5044 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9751 = true;\n        _9752 = _5027;\n        _9753 = _5044;\n        _9754 = _5044 * _5044;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5044;\n        float _5061 = fa_sheen_albedo(param, param_1);\n        _9756 = _5061;\n        _9755 = 1.0 - min(_5036 * _5061, 1.0);\n        _9741 = true;\n    }\n    _9744 = _9743 * _9755;\n    float _5080 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5080 != 0.0)\n    {\n        vec3 _5095 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5095;\n        if (dot(_5095, _5095) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5107 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5107.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5107.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5107.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5111 = t;\n        vec3 _5112 = normalize(_5111);\n        t = _5112;\n        vec3 _5137 = normalize((_5112 * cos(s.anisotropy_rotation)) + ((cross(n, _5112) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9758 = _5137;\n        _9759 = cross(n, _5137);\n        float _5147 = roughness * roughness;\n        float _5153 = mix(_5147, 1.0, _5080 * _5080);\n        bool _5155 = _5080 > 0.0;\n        _9760 = _5155 ? _5153 : _5147;\n        _9761 = _5155 ? _5147 : _5153;\n        _9757 = _5080;\n        _9741 = true;\n    }\n    return FaLayers(_9741, _9742, _9743, _9744, _9745, _9746, _9747, _9748, i.world_normal, _9750, _9751, _9752, _9753, _9754, _9755, _9756, _9757, _9758, _9759, _9760, _9761);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3948 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3948;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4559 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4564 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4559 > 0.0005000000237487256526947021484375)\n    {\n        if (_4564)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4559;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4559;\n        }\n    }\n    bool _4615 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4615)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4646 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4646)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4564 || _4615) || _4646)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3968 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3971 = _3968.x;\n    float _3973 = _3968.z;\n    vec2 e = vec2(_3971, _3973);\n    if (_3968.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3973)) * ((_3971 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3971)) * ((_3973 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7955 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7960 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7965 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7970 = fa_light_texel(param_3);\n    bool _7973 = _7970.z < 0.5;\n    bool _7981;\n    if (!_7973)\n    {\n        _7981 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7981 = _7973;\n    }\n    if (_7981)\n    {\n        return vec3(0.0);\n    }\n    float _7988 = max(_7955.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7991 = _7960.xyz;\n    vec3 _7995 = _7955.xyz;\n    vec3 _7999 = (fa_world_pos - _7995) / vec3(_7988);\n    vec3 _8008 = min(_7999 + vec3(0.5), (_7991 - vec3(0.5)) - _7999);\n    float _8017 = min(_8008.x, min(_8008.y, _8008.z));\n    if (!(_8017 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8032 = _7991 - vec3(1.0);\n    vec3 _8033 = clamp(_7999, vec3(0.0), _8032);\n    vec3 _8041 = min(floor(_8033), max(_7991 - vec3(2.0), vec3(0.0)));\n    vec3 _8045 = _8033 - _8041;\n    vec3 _8056 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7988));\n    int _8061 = int(_7965.y + 0.5);\n    float _8066 = 0.3257350027561187744140625 * n.y;\n    float _8070 = 0.3257350027561187744140625 * n.z;\n    float _8074 = 0.3257350027561187744140625 * n.x;\n    float _8081 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8088 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8097 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8104 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8117 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8124 = 8 + int(_7970.w);\n    float _8151;\n    float _8164;\n    float _8178;\n    for (int k = 0; k < _8124; k++)\n    {\n        float _8137 = float(k & 1);\n        float _8141 = float((k >> 1) & 1);\n        float _8145 = float((k >> 2) & 1);\n        if (_8137 > 0.5)\n        {\n            _8151 = _8045.x;\n        }\n        else\n        {\n            _8151 = 1.0 - _8045.x;\n        }\n        if (_8141 > 0.5)\n        {\n            _8164 = _8045.y;\n        }\n        else\n        {\n            _8164 = 1.0 - _8045.y;\n        }\n        if (_8145 > 0.5)\n        {\n            _8178 = _8045.z;\n        }\n        else\n        {\n            _8178 = 1.0 - _8045.z;\n        }\n        float _8188 = (_8151 * _8164) * _8178;\n        if (!(_8188 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8201 = min(_8041 + vec3(_8137, _8141, _8145), _8032);\n        int _8221 = int(((_7965.x + _8201.x) + (_7960.x * (_8201.y + (_7960.y * _8201.z)))) + 0.5);\n        vec2 _8236 = vec2(float(_8221 % _8061) * 10.0, 1024.0 + (float(_8221 / _8061) * 11.0));\n        vec2 param_4 = _8236 + vec2(9.5, 10.5);\n        vec4 _8244 = fa_gi_fetch(param_4);\n        bool _8247 = _8244.y < 0.5;\n        bool _8256;\n        if (!_8247)\n        {\n            _8256 = _8244.x > _7970.y;\n        }\n        else\n        {\n            _8256 = _8247;\n        }\n        if (_8256)\n        {\n            continue;\n        }\n        vec3 _8268 = _8056 - (_7995 + (_8201 * _7988));\n        float _8271 = length(_8268);\n        vec3 _8277 = _8268 / vec3(max(_8271, 9.9999997473787516355514526367188e-05));\n        float _8287 = max(9.9999997473787516355514526367188e-05, (dot(-_8277, n) + 1.0) * 0.5);\n        float w = _8188 * (_8287 * _8287);\n        vec3 param_5 = _8277;\n        vec2 param_6 = (_8236 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8306 = fa_gi_fetch(param_6);\n        float _8313 = _8271 / max(_7965.z, 9.9999997473787516355514526367188e-05);\n        float _8316 = _8306.x;\n        if (_8313 > _8316)\n        {\n            float _8329 = max(_8306.y - (_8316 * _8316), 0.0);\n            float _8334 = _8313 - _8316;\n            float _8343 = _8329 / max(_8329 + (_8334 * _8334), 9.9999999600419720025001879548654e-13);\n            w *= ((_8343 * _8343) * _8343);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8236 + vec2(0.5, 10.5);\n        vec2 param_8 = _8236 + vec2(1.5, 10.5);\n        vec2 param_9 = _8236 + vec2(2.5, 10.5);\n        vec2 param_10 = _8236 + vec2(3.5, 10.5);\n        vec2 param_11 = _8236 + vec2(4.5, 10.5);\n        vec2 param_12 = _8236 + vec2(5.5, 10.5);\n        vec2 param_13 = _8236 + vec2(6.5, 10.5);\n        vec2 param_14 = _8236 + vec2(7.5, 10.5);\n        vec2 param_15 = _8236 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8066)) + (fa_gi_fetch(param_9).xyz * _8070)) + (fa_gi_fetch(param_10).xyz * _8074)) + (fa_gi_fetch(param_11).xyz * _8081)) + (fa_gi_fetch(param_12).xyz * _8088)) + (fa_gi_fetch(param_13).xyz * _8097)) + (fa_gi_fetch(param_14).xyz * _8104)) + (fa_gi_fetch(param_15).xyz * _8117)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8017 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8467;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8467 = _7970.x;\n    }\n    else\n    {\n        _8467 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7965.w * _8467);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8491 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8496 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8501 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8501) && (k < 8); k++)\n    {\n        int param = _8496 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8491;\n        vec3 _8526 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8531 = param_3 * left;\n        acc += (_8526 * _8531);\n        left -= _8531;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8560 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8560;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8602 = vec4(fa_world_pos, 1.0);\n        vec2 _8621 = vec2(dot(fa_mesh_fs_params[26], _8602), dot(fa_mesh_fs_params[27], _8602)) / vec2(max(dot(fa_mesh_fs_params[28], _8602), 9.9999997473787516355514526367188e-05));\n        float _8630;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8630 = (_8621.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8630 = 0.5 - (_8621.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8621.x * 0.5) + 0.5, _8630) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6457;\n    if (fa_lm.z > 0.5)\n    {\n        _6457 = 0.0;\n    }\n    else\n    {\n        _6457 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6468 = _6457 < 1.0;\n    bool _6474;\n    if (_6468)\n    {\n        int param = li;\n        _6474 = fa_light_baked(param);\n    }\n    else\n    {\n        _6474 = _6468;\n    }\n    return _6474 ? _6457 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _884 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _897 = (c - (ru * hx)) - p;\n        vec3 _903 = ru * (2.0 * hx);\n        float _909 = max(dot(_903, _903), 9.9999999392252902907785028219223e-09);\n        float _913 = dot(_897, _903);\n        float t = clamp((-_913) / _909, 0.0, 1.0);\n        if (_884)\n        {\n            float _928 = dot(r, _903);\n            float _934 = _909 - (_928 * _928);\n            if (abs(_934) > (9.9999997473787516355514526367188e-06 * _909))\n            {\n                t = clamp(((dot(r, _897) * _928) - _913) / _934, 0.0, 1.0);\n            }\n        }\n        return (p + _897) + (_903 * t);\n    }\n    vec3 q = p;\n    float _966 = dot(r, axis);\n    bool _974;\n    if (_884)\n    {\n        _974 = abs(_966) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _974 = _884;\n    }\n    if (_974)\n    {\n        float _984 = dot(c - p, axis) / _966;\n        if (_984 > 0.0)\n        {\n            q = p + (r * _984);\n        }\n    }\n    vec3 _997 = q - c;\n    vec2 xy = vec2(dot(_997, ru), dot(_997, uu));\n    if (shape > 0.5)\n    {\n        float _1012 = length(xy);\n        if (_1012 > hx)\n        {\n            xy *= (hx / _1012);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _651 = abs(d);\n    float _653 = _651.x;\n    float _655 = _651.y;\n    bool _656 = _653 >= _655;\n    bool _664;\n    if (_656)\n    {\n        _664 = _653 >= _651.z;\n    }\n    else\n    {\n        _664 = _656;\n    }\n    int _665;\n    if (_664)\n    {\n        _665 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _679;\n        if (_655 >= _651.z)\n        {\n            _679 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _679 = (d.z > 0.0) ? 4 : 5;\n        }\n        _665 = _679;\n    }\n    return _665;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _804 = dot(d, right);\n    float _808 = dot(d, up);\n    float _819;\n    if (((_804 * _804) + (_808 * _808)) > 1.0000000133514319600180897396058e-10)\n    {\n        _819 = atan(_808, _804) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _819 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_819 - floor(_819)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1050 = fa_light_base(param);\n    bool _1054 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1050;\n    vec4 _1058 = fa_light_texel(param_1);\n    int param_2 = _1050 + 1;\n    vec4 _1063 = fa_light_texel(param_2);\n    float _1066 = _1063.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1078 = _1054 && (_1066 > 2.5);\n    fa_light_is_area = _1078;\n    bool _1080 = _1066 < 0.5;\n    vec3 l;\n    if (_1080)\n    {\n        l = normalize(_1058.xyz);\n        if (_1054)\n        {\n            int param_3 = _1050 + 6;\n            vec4 _1094 = fa_light_texel(param_3);\n            if (_1094.z > 0.5)\n            {\n                int param_4 = _1050 + 4;\n                vec4 _1104 = fa_light_texel(param_4);\n                int param_5 = _1050 + 5;\n                vec4 _1109 = fa_light_texel(param_5);\n                vec2 param_6 = _1094.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1104.xyz) * _1104.w, (-dot(world_pos, _1109.xyz)) * _1109.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1139 = _1058.xyz;\n        vec3 _1141 = _1139 - world_pos;\n        vec3 to_light = _1141;\n        float _1144 = length(_1141);\n        float reach = _1144;\n        bool front = true;\n        if (_1078)\n        {\n            int param_8 = _1050 + 7;\n            reach = max(_1144 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1050 + 4;\n            vec4 _1168 = fa_light_texel(param_9);\n            int param_10 = _1050 + 5;\n            vec4 _1173 = fa_light_texel(param_10);\n            int param_11 = _1050 + 6;\n            vec4 _1178 = fa_light_texel(param_11);\n            float _1179 = _1178.w;\n            int param_12 = _1050 + 2;\n            vec3 _1186 = normalize(fa_light_texel(param_12).xyz);\n            bool _1188 = _1179 > 1.5;\n            bool _1196;\n            if (!_1188)\n            {\n                _1196 = dot(_1186, to_light) < 0.0;\n            }\n            else\n            {\n                _1196 = _1188;\n            }\n            front = _1196;\n            vec3 r = vec3(0.0);\n            vec3 _1205 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1209 = dot(n, n) > 0.5;\n            bool _1217;\n            if (_1209)\n            {\n                _1217 = dot(_1205, _1205) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1217 = _1209;\n            }\n            if (_1217)\n            {\n                r = reflect(-normalize(_1205), normalize(n));\n            }\n            vec3 param_13 = _1139;\n            vec3 param_14 = _1186;\n            vec3 param_15 = _1168.xyz;\n            vec3 param_16 = _1173.xyz;\n            float param_17 = _1168.w;\n            float param_18 = _1173.w;\n            float param_19 = _1179;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1253 = length(to_light);\n        dist = _1253;\n        l = to_light / vec3(max(_1253, 9.9999997473787516355514526367188e-05));\n        float _1267 = reach / max(_1058.w, 0.001000000047497451305389404296875);\n        float _1273 = clamp(1.0 - (_1267 * _1267), 0.0, 1.0);\n        float _1275;\n        if (front)\n        {\n            _1275 = _1273 * _1273;\n        }\n        else\n        {\n            _1275 = 0.0;\n        }\n        atten = _1275;\n        bool _1286 = _1066 < 2.5;\n        if ((_1066 > 1.5) && _1286)\n        {\n            int param_22 = _1050 + 2;\n            vec4 _1294 = fa_light_texel(param_22);\n            float _1304 = _1294.w;\n            int param_23 = _1050 + 3;\n            vec4 _1309 = fa_light_texel(param_23);\n            float _1310 = _1309.x;\n            float cos_inner = _1310;\n            if (_1310 > 1.5)\n            {\n                cos_inner = mix(_1304, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1304, cos_inner, dot(-l, normalize(_1294.xyz)));\n        }\n        if (_1054 && (_1066 < 1.5))\n        {\n            int param_24 = _1050 + 6;\n            vec4 _1334 = fa_light_texel(param_24);\n            if (_1334.z > 0.5)\n            {\n                vec3 _1342 = -to_light;\n                int param_25 = _1050 + 4;\n                int param_26 = _1050 + 5;\n                vec3 _1356 = fa_light_texel(param_25).xyz;\n                vec3 _1360 = fa_light_texel(param_26).xyz;\n                vec3 _1369 = vec3(dot(_1342, _1356), dot(_1342, _1360), dot(_1342, cross(_1356, _1360)));\n                vec3 param_27 = _1369;\n                int _1373 = fa_cube_face(param_27);\n                int param_28 = _1373;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1400 = vec2(dot(_1369, cross(param_29, param_30)), dot(_1369, param_30)) / vec2(max(dot(_1369, param_29), 9.9999997473787516355514526367188e-05));\n                int _1404 = _1373 / 3;\n                vec2 param_31 = _1334.xy + (vec2(float(_1373 - (_1404 * 3)), float(_1404)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1400.x), 0.5 - (0.5 * _1400.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1050 + 7;\n            vec4 _1434 = fa_light_texel(param_33);\n            if (_1434.z > 0.5)\n            {\n                int param_34 = _1050 + 2;\n                int param_35 = _1050 + 4;\n                int param_36 = _1050 + 5;\n                vec2 param_37 = _1434.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1054 && _1286)\n            {\n                int param_42 = _1050 + 6;\n                vec4 _1481 = fa_light_texel(param_42);\n                int param_43 = _1050 + 7;\n                vec4 _1486 = fa_light_texel(param_43);\n                bool _1489 = _1481.z > 0.5;\n                bool _1496;\n                if (!_1489)\n                {\n                    _1496 = _1486.z > 0.5;\n                }\n                else\n                {\n                    _1496 = _1489;\n                }\n                if (_1496)\n                {\n                    int param_44 = _1050 + 2;\n                    vec4 _1503 = fa_light_texel(param_44);\n                    vec3 _1507 = normalize(_1503.xyz);\n                    int param_45 = _1050 + 4;\n                    vec4 _1512 = fa_light_texel(param_45);\n                    int param_46 = _1050 + 5;\n                    vec4 _1517 = fa_light_texel(param_46);\n                    if (_1489)\n                    {\n                        vec3 _1525 = -to_light;\n                        float _1532 = _1503.w;\n                        float _1548 = 0.5 / max(dot(_1525, _1507) * (sqrt(max(1.0 - (_1532 * _1532), 0.0)) / max(_1532, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1481.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1525, _1512.xyz) * _1548), 0.5 - (dot(_1525, _1517.xyz) * _1548));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1486.z > 0.5)\n                    {\n                        vec2 param_49 = _1486.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1507;\n                        vec3 param_52 = _1512.xyz;\n                        vec3 param_53 = _1517.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9729 = _1063.xyz * atten;\n    if (_1054)\n    {\n        _9729 *= fa_light_tint;\n    }\n    int _1617;\n    if (_1080)\n    {\n        _1617 = 0;\n    }\n    else\n    {\n        _1617 = ((_1066 > 1.5) && (_1066 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9729, atten, 1.0, dist, _1617);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2343;\n    if (i == 0)\n    {\n        _2343 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2359;\n        if (i == 1)\n        {\n            _2359 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2367;\n            if (i == 2)\n            {\n                _2367 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2367 = fa_shadows[24].w;\n            }\n            _2359 = _2367;\n        }\n        _2343 = _2359;\n    }\n    return _2343;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2400 = fa_shadow_depth(param, param_1);\n    float _2404;\n    if (conv.x < 0.5)\n    {\n        _2404 = _2400;\n    }\n    else\n    {\n        _2404 = (conv.y * conv.z) / (conv.z - (_2400 * (conv.z - conv.y)));\n    }\n    return _2404;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2450 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2456 = vec2(cos(_2450), sin(_2450));\n    vec2 dir = _2456;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2465;\n        if (k < 0.0)\n        {\n            _2465 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2465 = k;\n        }\n        float _2484 = clamp((_2465 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2503 = sqrt((float(i) + 0.5) * 0.0625) * _2484;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2503));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2517 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2517 < (zr - (_2503 * plane)))\n            {\n                sum += _2517;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2545 = sum / cnt;\n        float _2555;\n        if (k < 0.0)\n        {\n            _2555 = (-k) / max(_2545, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2555 = k;\n        }\n        radius = clamp(((max(zr - _2545, 0.0) * unit) * _2555) / texel_m, 1.5, 16.0);\n        dir = _2456;\n    }\n    float lit = 0.0;\n    int _2581 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2581; i_1++)\n    {\n        float _2600 = sqrt((float(i_1) + 0.5) / float(_2581)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2600));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2600 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2581);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2646 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2651 = clamp(dot(n, l), 0.0, 1.0);\n    float _2657 = sqrt(1.0 - (_2651 * _2651));\n    float _2665 = min(_2657 / max(_2651, 0.20000000298023223876953125), 4.0);\n    float _2670;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2670 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2670 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2695 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2670 * _2657)), 1.0);\n    float _2702 = _2695.x;\n    bool _2705 = _2702 < fa_shadows[ci * 1 + 16].x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2695.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2695.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    bool _2739;\n    if (!_2732)\n    {\n        _2739 = _2695.z > 1.0;\n    }\n    else\n    {\n        _2739 = _2732;\n    }\n    if (_2739)\n    {\n        return -1.0;\n    }\n    float _2747;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2747 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2747 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2695.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2695.z - ((_2747 * (1.0 + (0.5 * _2665))) / _2646);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2646;\n    float param_5 = _2646 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2665, 3.0)) * 0.5) / _2646;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3125 = int(fa_shadows[25].x + 0.5);\n    if (_3125 < 1)\n    {\n        return 1.0;\n    }\n    float _3140 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3125 - 1;\n    if (_3140 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3152 = _3125 > 1;\n    bool _3159;\n    if (_3152)\n    {\n        _3159 = _3140 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3159 = _3152;\n    }\n    if (_3159)\n    {\n        ci = 1;\n    }\n    bool _3163 = _3125 > 2;\n    bool _3170;\n    if (_3163)\n    {\n        _3170 = _3140 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3170 = _3163;\n    }\n    if (_3170)\n    {\n        ci = 2;\n    }\n    bool _3174 = _3125 > 3;\n    bool _3181;\n    if (_3174)\n    {\n        _3181 = _3140 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3181 = _3174;\n    }\n    if (_3181)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3192 = min(_3125, 4);\n    float _3233;\n    for (int c = ci; c < _3192; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3212 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3212;\n            break;\n        }\n        if (_3212 < 0.0)\n        {\n            continue;\n        }\n        s = _3212;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3233 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3233 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3252 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3233, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3140 - (fa_shadow_split_at(param_7) - _3252)) / _3252, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3284;\n        if ((ci + 1) < _3125)\n        {\n            _3284 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3284 = 1.0;\n        }\n        s = mix(s, _3284, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3389 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3395;\n    if (_3389)\n    {\n        _3395 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3395 = _3389;\n    }\n    if (_3395)\n    {\n        float _3409 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3412 = fwidth(_3409);\n        vec4 _3422 = vec4(fa_world_pos, 1.0);\n        float _3428 = dot(fa_mesh_fs_params[28], _3422);\n        if (_3428 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3447 = vec2(dot(fa_mesh_fs_params[26], _3422), dot(fa_mesh_fs_params[27], _3422)) / vec2(_3428);\n            float _3452 = (_3447.x * 0.5) + 0.5;\n            float _3456;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3456 = (_3447.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3456 = 0.5 - (_3447.y * 0.5);\n            }\n            bool _3472 = _3452 >= 0.0;\n            bool _3478;\n            if (_3472)\n            {\n                _3478 = _3452 < 1.0;\n            }\n            else\n            {\n                _3478 = _3472;\n            }\n            bool _3484;\n            if (_3478)\n            {\n                _3484 = _3456 >= 0.0;\n            }\n            else\n            {\n                _3484 = _3478;\n            }\n            bool _3490;\n            if (_3484)\n            {\n                _3490 = _3456 < 1.0;\n            }\n            else\n            {\n                _3490 = _3484;\n            }\n            if (_3490)\n            {\n                vec4 _3516 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3452, _3456) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3519 = _3516.w > 0.5;\n                bool _3535;\n                if (_3519)\n                {\n                    _3535 = abs(_3409 - _3516.x) <= (((0.00200000009499490261077880859375 * _3409) + 0.00999999977648258209228515625) + min(1.5 * _3412, 0.100000001490116119384765625 * _3409));\n                }\n                else\n                {\n                    _3535 = _3519;\n                }\n                if (_3535)\n                {\n                    float _3541;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3541 = min(_3516.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3541 = _3516.y;\n                    }\n                    return _3541;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2805 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2812;\n    if (!_2805)\n    {\n        _2812 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2812 = _2805;\n    }\n    if (_2812)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2825 = fa_light_texel(param);\n    float _2826 = _2825.x;\n    if (_2826 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2835 = int(_2826 + 0.5);\n    int param_1 = _2835;\n    vec4 _2839 = fa_light_texel(param_1);\n    int param_2 = _2835 + 1;\n    vec4 _2844 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2847 = _2839.y;\n    if (_2847 > 0.0)\n    {\n        float _2864 = 1.0 - smoothstep(0.75 * _2847, _2847, length(world - fa_shadows[27].xyz));\n        fade = _2864;\n        if (_2864 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2839.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2888 = (_2835 + 2) + (face * 6);\n    int param_4 = _2888;\n    int param_5 = _2888 + 1;\n    int param_6 = _2888 + 3;\n    vec4 _2902 = fa_light_texel(param_6);\n    int param_7 = _2888 + 4;\n    vec4 _2907 = fa_light_texel(param_7);\n    int param_8 = _2888 + 5;\n    vec4 _2912 = fa_light_texel(param_8);\n    float _2924 = _2912.x * max(dot(_2902, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2929 = clamp(dot(n, l), 0.0, 1.0);\n    float _2952 = clamp(dot(n, _2902.xyz), -1.0, 1.0);\n    float _2971 = min(sqrt(1.0 - (_2952 * _2952)) / max(abs(dot(n, world - lpos)) / max(dot(_2902, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2974 = _2844.y;\n    float _2976;\n    if (_2974 > 0.0)\n    {\n        _2976 = _2974;\n    }\n    else\n    {\n        _2976 = 1.5 * _2924;\n    }\n    vec4 _2996 = vec4(world + (n * (_2976 * sqrt(1.0 - (_2929 * _2929)))), 1.0);\n    float _3000 = dot(_2902, _2996);\n    float _3003 = _2912.y;\n    if (_3000 < _3003)\n    {\n        return 1.0;\n    }\n    vec2 _3018 = vec2(dot(fa_light_texel(param_4), _2996), dot(fa_light_texel(param_5), _2996)) / vec2(_3000);\n    float _3020 = _3018.x;\n    bool _3023 = _3020 < _2907.x;\n    bool _3032;\n    if (!_3023)\n    {\n        _3032 = _3020 > _2907.z;\n    }\n    else\n    {\n        _3032 = _3023;\n    }\n    bool _3041;\n    if (!_3032)\n    {\n        _3041 = _3018.y < _2907.y;\n    }\n    else\n    {\n        _3041 = _3032;\n    }\n    bool _3050;\n    if (!_3041)\n    {\n        _3050 = _3018.y > _2907.w;\n    }\n    else\n    {\n        _3050 = _3041;\n    }\n    if (_3050)\n    {\n        return 1.0;\n    }\n    float _3056 = _2844.x;\n    float _3058;\n    if (_3056 > 0.0)\n    {\n        _3058 = _3056;\n    }\n    else\n    {\n        _3058 = 1.5 * _2924;\n    }\n    vec2 param_9 = _3018;\n    vec4 param_10 = _2907;\n    float param_11 = _3000 - (_3058 * (1.0 + (0.5 * _2971)));\n    float param_12 = _2924;\n    float param_13 = 1.0;\n    float param_14 = _2912.z * 0.25;\n    float param_15 = (_2924 * min(_2971, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _3003, _2912.z);\n    int param_17 = int(_2839.z + 0.5);\n    float param_18 = _2839.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3570 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3576;\n    if (_3570)\n    {\n        _3576 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3576 = _3570;\n    }\n    bool _3582;\n    if (_3576)\n    {\n        _3582 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3582 = _3576;\n    }\n    if (_3582)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3594 = fa_light_texel(param);\n        float _3595 = _3594.z;\n        if (_3595 > 0.5)\n        {\n            float _3608 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3611 = fwidth(_3608);\n            float _3615 = min(1.5 * _3611, 0.100000001490116119384765625 * _3608);\n            vec4 _3621 = vec4(world, 1.0);\n            float _3626 = dot(fa_mesh_fs_params[28], _3621);\n            if (_3626 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3643 = vec2(dot(fa_mesh_fs_params[26], _3621), dot(fa_mesh_fs_params[27], _3621)) / vec2(_3626);\n                float _3648 = (_3643.x * 0.5) + 0.5;\n                float _3652;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3652 = (_3643.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3652 = 0.5 - (_3643.y * 0.5);\n                }\n                bool _3668 = _3648 >= 0.0;\n                bool _3674;\n                if (_3668)\n                {\n                    _3674 = _3648 < 1.0;\n                }\n                else\n                {\n                    _3674 = _3668;\n                }\n                bool _3680;\n                if (_3674)\n                {\n                    _3680 = _3652 >= 0.0;\n                }\n                else\n                {\n                    _3680 = _3674;\n                }\n                bool _3686;\n                if (_3680)\n                {\n                    _3686 = _3652 < 1.0;\n                }\n                else\n                {\n                    _3686 = _3680;\n                }\n                if (_3686)\n                {\n                    ivec2 _3703 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3704 = clamp(ivec2(vec2(_3648, _3652) * fa_mesh_fs_params[24].zw), ivec2(0), _3703);\n                    ivec2 _3716;\n                    ivec2 _3722;\n                    ivec2 _3729;\n                    float _3780;\n                    float _3801;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3716 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3722 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3729 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3740 = bvec2(k == 3);\n                                    _3729 = ivec2(_3740.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3740.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3722 = _3729;\n                            }\n                            _3716 = _3722;\n                        }\n                        vec4 _3757 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3704 + _3716, ivec2(0), _3703), 0);\n                        bool _3760 = _3757.w > 0.5;\n                        bool _3774;\n                        if (_3760)\n                        {\n                            _3774 = abs(_3608 - _3757.x) <= (((0.00200000009499490261077880859375 * _3608) + 0.00999999977648258209228515625) + _3615);\n                        }\n                        else\n                        {\n                            _3774 = _3760;\n                        }\n                        if (_3774)\n                        {\n                            if (_3595 < 1.5)\n                            {\n                                _3780 = 1.0;\n                            }\n                            else\n                            {\n                                _3780 = (_3595 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3797 = mod(floor(_3757.z / _3780), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3801 = min(_3797, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3801 = _3797;\n                            }\n                            return _3801;\n                        }\n                    }\n                }\n            }\n            float _3826;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3826 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3826 = 1.0;\n            }\n            return _3826;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5671 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5678;\n    if (!_5671)\n    {\n        _5678 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5678 = _5671;\n    }\n    if (_5678)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5691 = fa_light_texel(param);\n    float _5692 = _5691.y;\n    float len = _5692;\n    if (_5692 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5704 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5713 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5704);\n    if (_5713 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5719 = len;\n    float _5722 = min(_5719, 0.89999997615814208984375 * dist);\n    len = _5722;\n    float _5727 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5704);\n    float _5732 = _5727 + (0.5 * _5722);\n    vec3 _5738 = world + (gn * _5727);\n    float _5740 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5801;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5755 = (float(k) + _5740) * 0.083333335816860198974609375;\n        vec3 _5763 = _5738 + (l * (_5755 * len));\n        vec4 _5769 = vec4(_5763, 1.0);\n        float _5774 = dot(fa_mesh_fs_params[28], _5769);\n        if (_5774 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5792 = vec2(dot(fa_mesh_fs_params[26], _5769), dot(fa_mesh_fs_params[27], _5769)) / vec2(_5774);\n        float _5796 = _5792.x * 0.5;\n        float _5797 = _5796 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5801 = (_5792.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5801 = 0.5 - (_5792.y * 0.5);\n        }\n        bool _5817 = _5797 < 0.0;\n        bool _5824;\n        if (!_5817)\n        {\n            _5824 = _5797 >= 1.0;\n        }\n        else\n        {\n            _5824 = _5817;\n        }\n        bool _5831;\n        if (!_5824)\n        {\n            _5831 = _5801 < 0.0;\n        }\n        else\n        {\n            _5831 = _5824;\n        }\n        bool _5838;\n        if (!_5831)\n        {\n            _5838 = _5801 >= 1.0;\n        }\n        else\n        {\n            _5838 = _5831;\n        }\n        if (_5838)\n        {\n            break;\n        }\n        vec4 _5862 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5797, _5801) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5862.w < 0.5)\n        {\n            continue;\n        }\n        float _5880 = (dot(fa_mesh_fs_params[29].xyz, _5763) + fa_mesh_fs_params[29].w) - _5862.x;\n        if ((_5880 > _5727) && (_5880 < _5732))\n        {\n            occ = max(occ, (1.0 - (_5755 * _5755)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5797, 0.5 - _5796), min(_5801, 1.0 - _5801))));\n        }\n    }\n    return 1.0 - (occ * _5713);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6513 = fa_baked_keep(param);\n    if (_6513 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6539 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9798 = _6539.color;\n    float _9799 = _6539.attenuation;\n    float _9800 = _6539.shadow;\n    bool _6542 = _6539.type == 0;\n    if (_6542 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6539.direction;\n        float _6553 = fa_shadow_factor(param_5, param_6);\n        _9800 = _6553;\n        _9798 *= _6553;\n    }\n    else\n    {\n        bool _6564 = _6539.type != 0;\n        bool _6570;\n        if (_6564)\n        {\n            _6570 = _9799 > 0.0;\n        }\n        else\n        {\n            _6570 = _6564;\n        }\n        if (_6570)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6539.direction;\n            float _6589 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9800 = _6589;\n            _9798 *= _6589;\n        }\n    }\n    bool _6599 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6605;\n    if (_6599)\n    {\n        _6605 = _9799 > 0.0;\n    }\n    else\n    {\n        _6605 = _6599;\n    }\n    if (_6605)\n    {\n        float _6612;\n        if (_6542)\n        {\n            _6612 = 1000000000.0;\n        }\n        else\n        {\n            _6612 = _6539._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6539.direction;\n        float param_18 = _6612;\n        float _6630 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9800 *= _6630;\n        _9798 *= _6630;\n    }\n    float _6643 = _9799;\n    float _6644 = _6643 * _6513;\n    _9799 = _6644;\n    vec3 _6648 = _9798;\n    vec3 _6649 = _6648 * _6513;\n    _9798 = _6649;\n    return LightSample(_6539.direction, _6649, _6644, _9800, _6539._distance, _6539.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6683 = v - (n * dot(v, n));\n    vec3 t = _6683;\n    float _6687 = dot(_6683, _6683);\n    float l2 = _6687;\n    if (_6687 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6697;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6697 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6697 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6697;\n        l2 = dot(_6697, _6697);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7084;\n    if ((j == 0) || (j == 7))\n    {\n        _7084 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7094;\n        if ((j == 3) || (j == 4))\n        {\n            _7094 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7094 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7084 = _7094;\n    }\n    float _7115;\n    if ((j == 1) || (j == 2))\n    {\n        _7115 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7124;\n        if ((j == 5) || (j == 6))\n        {\n            _7124 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7124 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7115 = _7124;\n    }\n    return (pc + (ex * _7084)) + (ey * _7115);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6732 = dot(a, a);\n    float _6736 = dot(b, b);\n    if ((_6732 < 1.0000000195414813782625560981111e-24) || (_6736 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6750 = a * inversesqrt(_6732);\n    vec3 _6755 = b * inversesqrt(_6736);\n    float _6759 = dot(_6750, _6755);\n    float _6762 = abs(_6759);\n    float g = (((((((((((0.0416471660137176513671875 * _6762) - 0.1924748718738555908203125) * _6762) + 0.4179156124591827392578125) * _6762) - 0.616057217121124267578125) * _6762) + 0.777722418308258056640625) * _6762) - 0.999542415142059326171875) * _6762) + 1.570791721343994140625;\n    if (_6759 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6759 * _6759), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6750, _6755) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6819 = a.z > 0.0;\n    bool _6823 = b.z > 0.0;\n    if (_6819 && _6823)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6819 != _6823)\n        {\n            vec3 _6858 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6858.z = 0.0;\n            if (_6819)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6858;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6858;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6858;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6858;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6907 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6933 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6959 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6985 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6907;\n    vec3 param_1 = _6933;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6933;\n    vec3 param_7 = _6959;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6959;\n    vec3 param_13 = _6985;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6985;\n    vec3 param_19 = _6907;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7153 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7171;\n    for (int k = 0; k < (2 * _7153); k++)\n    {\n        bool _7168 = k >= _7153;\n        if (_7168)\n        {\n            _7171 = k - _7153;\n        }\n        else\n        {\n            _7171 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7153 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7217 = 2 * _7171;\n            int param_4 = _7217 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7217 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7217 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7254 = bvec4(_7168);\n        vec4 param_16 = vec4(_7254.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7254.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7254.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7254.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7265 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7168)\n        {\n            vec2 _10051 = sum;\n            _10051.y = _10051.y + _7265;\n            sum = _10051;\n        }\n        else\n        {\n            vec2 _10054 = sum;\n            _10054.x = _10054.x + _7265;\n            sum = _10054;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7289 = fa_light_base(param);\n    int param_1 = _7289;\n    int param_2 = _7289 + 1;\n    int param_3 = _7289 + 2;\n    int param_4 = _7289 + 4;\n    vec4 _7311 = fa_light_texel(param_4);\n    int param_5 = _7289 + 5;\n    vec4 _7316 = fa_light_texel(param_5);\n    int param_6 = _7289 + 6;\n    vec4 _7321 = fa_light_texel(param_6);\n    float _7322 = _7321.w;\n    vec3 _7327 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7329 = _7322 < 1.5;\n    bool _7336;\n    if (_7329)\n    {\n        _7336 = dot(normalize(fa_light_texel(param_3).xyz), _7327) >= 0.0;\n    }\n    else\n    {\n        _7336 = _7329;\n    }\n    if (_7336)\n    {\n        return vec3(0.0);\n    }\n    bool _7345 = (_7322 > 0.5) && _7329;\n    float _7349 = _7345 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7352 = _7311.xyz;\n    float _7354 = _7311.w;\n    vec3 _7360 = _7316.xyz;\n    float _7362 = _7316.w;\n    vec3 up = _7360 * (_7362 * _7349);\n    float _7368;\n    if (_7345)\n    {\n        _7368 = (3.1415927410125732421875 * _7354) * _7354;\n    }\n    else\n    {\n        _7368 = (4.0 * _7354) * _7362;\n    }\n    if (_7322 > 1.5)\n    {\n        vec3 _7394 = cross(_7352, -_7327);\n        vec3 perp = _7394;\n        float _7398 = dot(_7394, _7394);\n        vec3 _7401;\n        if (_7398 > 1.0000000133514319600180897396058e-10)\n        {\n            _7401 = perp * inversesqrt(_7398);\n        }\n        else\n        {\n            _7401 = _7360;\n        }\n        perp = _7401;\n        up = _7401 * _7362;\n    }\n    float _7422 = max(_7368, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7432 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7432;\n    vec3 param_10 = n;\n    vec3 param_11 = _7327;\n    vec3 param_12 = _7432;\n    vec3 param_13 = n;\n    vec3 param_14 = _7352 * (_7354 * _7349);\n    vec3 param_15 = _7432;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7463 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7463;\n    vec2 param_21 = _7463 + vec2(64.0, 0.0);\n    vec4 _7473 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7322;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7485 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7485.x) + (((f0 * _7473.x) + ((vec3(f90) - f0) * _7473.y)) * _7485.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7327, _7327)) + _7422) / _7422) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5408 = 1.0 / alpha;\n    return ((2.0 + _5408) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5408)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5443 = max(dot(L.nc, l), 0.0);\n    float _5449 = max(dot(L.nc, h), 0.0);\n    float _5458 = ((_5449 * _5449) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5458) * _5458)) * (0.5 / max(mix((2.0 * _5443) * L.coat_ndv, _5443 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5443)) * _5443;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7522;\n    if (L.sheen_on)\n    {\n        _7522 = L.sheen_scale;\n    }\n    else\n    {\n        _7522 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7522);\n    vec3 _7535 = normalize(l + v);\n    int param = li;\n    vec3 _7546 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7555 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7535), 0.0);\n        float param_3 = _7555;\n        float param_4 = ndv;\n        result += ((L.sheen * _7546) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7555)) * _7555) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7535;\n        float param_8 = max(dot(v, _7535), 0.0);\n        result += (_7546 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5311 = tdh / at;\n    float _5315 = bdh / ab;\n    float _5327 = ((_5311 * _5311) + (_5315 * _5315)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5327) * _5327);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5507 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5586 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5586) * _5586);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5507);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5507));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4710 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4713 = _4710.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4713 * _4713, exp2((-9.27999973297119140625) * ndv)) * _4713) + _4710.y)) + _4710.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4020;\n    if (lv == 0)\n    {\n        _4020 = 0.0;\n    }\n    else\n    {\n        _4020 = res + 2.0;\n    }\n    float _4030;\n    if (lv == 0)\n    {\n        _4030 = 0.0;\n    }\n    else\n    {\n        _4030 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4020, _4030)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4076;\n    if (res > 64.5)\n    {\n        _4076 = 5.0;\n    }\n    else\n    {\n        _4076 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4091 = clamp(rough, 0.0, 1.0) * (_4076 - 1.0);\n    int _4098 = int(min(floor(_4091), _4076 - 2.0));\n    float _4103 = _4091 - float(_4098);\n    vec3 param = d;\n    vec2 _4107 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4098;\n    vec2 param_4 = _4107;\n    vec3 _4117 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4103 < 0.00200000009499490261077880859375)\n    {\n        return _4117;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4098 + 1;\n    vec2 param_8 = _4107;\n    return mix(_4117, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4103));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4188 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4195 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4202 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4208 = dot(bx.xyz, d);\n    float _4212 = dot(by.xyz, d);\n    float _4216 = dot(bz.xyz, d);\n    float _4222;\n    if (_4208 > 9.9999999747524270787835121154785e-07)\n    {\n        _4222 = (1.0 - _4188) / _4208;\n    }\n    else\n    {\n        float _4236;\n        if (_4208 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4236 = ((-1.0) - _4188) / _4208;\n        }\n        else\n        {\n            _4236 = 1000000015047466219876688855040.0;\n        }\n        _4222 = _4236;\n    }\n    float tx = _4222;\n    float _4253;\n    if (_4212 > 9.9999999747524270787835121154785e-07)\n    {\n        _4253 = (1.0 - _4195) / _4212;\n    }\n    else\n    {\n        float _4266;\n        if (_4212 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4266 = ((-1.0) - _4195) / _4212;\n        }\n        else\n        {\n            _4266 = 1000000015047466219876688855040.0;\n        }\n        _4253 = _4266;\n    }\n    float ty = _4253;\n    float _4282;\n    if (_4216 > 9.9999999747524270787835121154785e-07)\n    {\n        _4282 = (1.0 - _4202) / _4216;\n    }\n    else\n    {\n        float _4295;\n        if (_4216 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4295 = ((-1.0) - _4202) / _4216;\n        }\n        else\n        {\n            _4295 = 1000000015047466219876688855040.0;\n        }\n        _4282 = _4295;\n    }\n    float _4307 = tx;\n    float _4310 = (_4307 > 0.0) ? _4307 : 1000000015047466219876688855040.0;\n    tx = _4310;\n    float _4311 = ty;\n    float _4314 = (_4311 > 0.0) ? _4311 : 1000000015047466219876688855040.0;\n    ty = _4314;\n    float _4324 = min(_4310, min(_4314, (_4282 > 0.0) ? _4282 : 1000000015047466219876688855040.0));\n    if (_4324 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4340 = (fa_world_pos + (d * _4324)) - posw.xyz;\n    vec3 _4345;\n    if (dot(_4340, _4340) > 1.0000000133514319600180897396058e-10)\n    {\n        _4345 = normalize(_4340);\n    }\n    else\n    {\n        _4345 = d;\n    }\n    return _4345;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4391 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4391 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4419 = rough * rough;\n            float _4450 = 0.60000002384185791015625 * _4419;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4419)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4450, 0.0500000007450580596923828125 + _4450, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4419 * 0.60000002384185791015625));\n        }\n        outc = base * _4391;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4509 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4509 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4541 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4541 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5188;\n        if (L.aniso >= 0.0)\n        {\n            _5188 = L.b;\n        }\n        else\n        {\n            _5188 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5188, v), _5188), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5224 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5224.x) + (vec3(L.f90) * _5224.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5282 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5282.x) + _5282.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4752 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4752.x) + vec3(_4752.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5984 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5988 = fa_xm_origin(param_1);\n    vec2 _5994 = (uv * _5984) - vec2(0.5);\n    vec2 _5997 = fract(_5994);\n    vec2 _6000 = floor(_5994);\n    vec2 param_2 = _5984;\n    vec2 param_3 = _5988;\n    vec2 param_4 = _6000;\n    vec2 param_5 = _5984;\n    vec2 param_6 = _5988;\n    vec2 param_7 = _6000 + vec2(1.0, 0.0);\n    vec2 param_8 = _5984;\n    vec2 param_9 = _5988;\n    vec2 param_10 = _6000 + vec2(0.0, 1.0);\n    vec2 param_11 = _5984;\n    vec2 param_12 = _5988;\n    vec2 param_13 = _6000 + vec2(1.0);\n    vec3 _6042 = vec3(_5997.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6042), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6042), vec3(_5997.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6061 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6065 = clamp(lod, 0.0, _6061);\n    int _6069 = int(floor(_6065));\n    int param = _6069;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6079 = float(_6069);\n    float _6080 = _6065 - _6079;\n    bool _6082 = _6080 > 0.001000000047497451305389404296875;\n    bool _6089;\n    if (_6082)\n    {\n        _6089 = _6079 < _6061;\n    }\n    else\n    {\n        _6089 = _6082;\n    }\n    if (_6089)\n    {\n        int param_2 = _6069 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6080));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6115 = fa_env_brdf(param, param_1);\n    vec3 _6139 = ((vec3(1.0) - clamp((f0 * _6115.x) + (vec3(f90) * _6115.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6139;\n    float _6145 = max(s.thickness, 0.0);\n    bool _6150 = _6145 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6150)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6145);\n    }\n    bool _6175 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6181;\n    if (_6175)\n    {\n        _6181 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6181 = _6175;\n    }\n    bool _6188;\n    if (!_6181)\n    {\n        _6188 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6188 = _6181;\n    }\n    if (_6188)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6203 = vec4(fa_world_pos, 1.0);\n    float _6208 = dot(fa_mesh_fs_params[28], _6203);\n    vec2 uv0 = vec2(0.5);\n    if (_6208 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6226 = vec2(dot(fa_mesh_fs_params[26], _6203), dot(fa_mesh_fs_params[27], _6203)) / vec2(_6208);\n        float _6234;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6234 = (_6226.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6234 = 0.5 - (_6226.y * 0.5);\n        }\n        uv0 = vec2((_6226.x * 0.5) + 0.5, _6234);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6255 = fa_xm_size(param_2);\n        vec2 _6263 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6255);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6263), 0).w > 0.5)\n        {\n            int _6283 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6306 = abs(dx) > _6283;\n                    bool _6314;\n                    if (!_6306)\n                    {\n                        _6314 = abs(dy) > _6283;\n                    }\n                    else\n                    {\n                        _6314 = _6306;\n                    }\n                    if (_6314)\n                    {\n                        continue;\n                    }\n                    vec4 _6335 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6263 + vec2(float(dx), float(dy)), vec2(0.0), _6255 - vec2(1.0))), 0);\n                    if (_6335.w > 0.5)\n                    {\n                        acc += _6335.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6139 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6150)\n    {\n        vec4 _6383 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6145), 1.0);\n        float _6388 = dot(fa_mesh_fs_params[28], _6383);\n        uv = vec2(0.5);\n        if (_6388 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6405 = vec2(dot(fa_mesh_fs_params[26], _6383), dot(fa_mesh_fs_params[27], _6383)) / vec2(_6388);\n            float _6413;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6413 = (_6405.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6413 = 0.5 - (_6405.y * 0.5);\n            }\n            uv = vec2((_6405.x * 0.5) + 0.5, _6413);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3312 = int(fa_shadows[25].x + 0.5);\n    float _3322 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3327 = _3312 > 0;\n    bool _3336;\n    if (_3327)\n    {\n        int param = _3312 - 1;\n        _3336 = _3322 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3336 = _3327;\n    }\n    if (_3336)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3342 = _3312 > 1;\n        bool _3349;\n        if (_3342)\n        {\n            _3349 = _3322 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3349 = _3342;\n        }\n        if (_3349)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3355 = _3312 > 2;\n        bool _3362;\n        if (_3355)\n        {\n            _3362 = _3322 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3362 = _3355;\n        }\n        if (_3362)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3368 = _3312 > 3;\n        bool _3375;\n        if (_3368)\n        {\n            _3375 = _3322 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3375 = _3368;\n        }\n        if (_3375)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _9457 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9457 = -_9457;\n    }\n    vec3 _8743 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9457, fa_world_tangent, fa_uv, fa_vertex_color, _8743, gl_FrontFacing);\n    Surface _8751 = fa_standard_surface(param_1);\n    vec3 _9488 = _8751.albedo;\n    float _9489 = _8751.alpha;\n    vec3 _9490 = _8751.normal;\n    float _9491 = _8751.metallic;\n    float _9492 = _8751.roughness;\n    float _9493 = _8751.occlusion;\n    vec3 _9494 = _8751.emission;\n    float _9495 = _8751.clearcoat;\n    float _9496 = _8751.clearcoat_roughness;\n    vec3 _9497 = _8751.sheen_color;\n    float _9498 = _8751.sheen_roughness;\n    float _9499 = _8751.anisotropy;\n    float _9500 = _8751.anisotropy_rotation;\n    float _9501 = _8751.specular;\n    float _9502 = _8751.ior;\n    vec3 _9503 = _8751.specular_color;\n    float _9504 = _8751.transmission;\n    float _9505 = _8751.thickness;\n    vec3 _9506 = _8751.attenuation_color;\n    float _9507 = _8751.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9457, fa_world_tangent, fa_uv, fa_vertex_color, _8743, gl_FrontFacing);\n    Surface param_3 = _8751;\n    surface(param_2, param_3);\n    _9488 = param_3.albedo;\n    _9489 = param_3.alpha;\n    _9490 = param_3.normal;\n    _9491 = param_3.metallic;\n    _9492 = param_3.roughness;\n    _9493 = param_3.occlusion;\n    _9494 = param_3.emission;\n    _9495 = param_3.clearcoat;\n    _9496 = param_3.clearcoat_roughness;\n    _9497 = param_3.sheen_color;\n    _9498 = param_3.sheen_roughness;\n    _9499 = param_3.anisotropy;\n    _9500 = param_3.anisotropy_rotation;\n    _9501 = param_3.specular;\n    _9502 = param_3.ior;\n    _9503 = param_3.specular_color;\n    _9504 = param_3.transmission;\n    _9505 = param_3.thickness;\n    _9506 = param_3.attenuation_color;\n    _9507 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9457;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9488 = param_6;\n    _9490 = param_7;\n    if (_9489 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9488;\n    }\n    else\n    {\n        vec3 _8803 = normalize(_9490);\n        float _8810 = clamp(_9491, 0.0, 1.0);\n        float _8814 = clamp(_9492, 0.0500000007450580596923828125, 1.0);\n        float _8818 = _8814 * _8814;\n        float _8822 = _8818 * _8818;\n        float _8827 = max(dot(_8803, _8743), 9.9999997473787516355514526367188e-05);\n        float _8833 = 1.0 - _8810;\n        float _8834 = clamp(_9504, 0.0, 1.0) * _8833;\n        vec3 _8843 = (_9488 * _8833) * (1.0 - _8834);\n        vec3 _8850 = mix(vec3(0.039999999105930328369140625), _9488, vec3(_8810));\n        vec3 f0 = _8850;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9457, fa_world_tangent, fa_uv, fa_vertex_color, _8743, gl_FrontFacing);\n        Surface param_9 = Surface(_9488, _9489, _9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, _9498, _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507);\n        vec3 param_10 = _8803;\n        vec3 param_11 = _8743;\n        float param_12 = _8810;\n        float param_13 = _8814;\n        vec3 param_14 = _8850;\n        FaLayers _8866 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8803;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8843) * _9493;\n        if (_8866.on)\n        {\n            lit *= _8866.base_scale;\n        }\n        int _8888 = fa_cl_ndir + fa_cl_local;\n        float _8953;\n        for (int ln = 0; ln < _8888; ln++)\n        {\n            int param_16 = ln;\n            int _8901 = fa_cl_light(param_16);\n            int param_17 = _8901;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8901;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9457;\n            LightSample _8917 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8925 = max(dot(_8803, _8917.direction), 0.0);\n            float _8931 = _8917.attenuation * _8917.shadow;\n            vec3 _8936 = normalize(_8917.direction + _8743);\n            float _8941 = max(dot(_8803, _8936), 0.0);\n            float _8946 = max(dot(_8743, _8936), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8866.on)\n                {\n                    _8953 = _8866.f90;\n                }\n                else\n                {\n                    _8953 = 1.0;\n                }\n                int param_21 = _8901;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8803;\n                vec3 param_24 = _8743;\n                vec3 param_25 = _8843;\n                vec3 param_26 = f0;\n                float param_27 = _8953;\n                float param_28 = _8814;\n                float param_29 = _8827;\n                float param_30 = _8931;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8866.on)\n                {\n                    FaLayers param_31 = _8866;\n                    vec3 param_32 = area;\n                    int param_33 = _8901;\n                    vec3 param_34 = _8803;\n                    vec3 param_35 = _8743;\n                    vec3 param_36 = _8917.direction;\n                    float param_37 = _8827;\n                    float param_38 = _8931;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8866.on)\n                {\n                    FaLayers param_39 = _8866;\n                    vec3 param_40 = _8843;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8803;\n                    vec3 param_43 = _8743;\n                    vec3 param_44 = _8917.direction;\n                    vec3 param_45 = _8936;\n                    float param_46 = _8925;\n                    float param_47 = _8827;\n                    float param_48 = _8941;\n                    float param_49 = _8946;\n                    float param_50 = _8818;\n                    float param_51 = _8822;\n                    int param_52 = _8901;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8931));\n                }\n                else\n                {\n                    float _9055 = ((_8941 * _8941) * (_8822 - 1.0)) + 1.0;\n                    int param_53 = _8901;\n                    lit += (((_8843 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8946, 5.0))) * (((_8822 / ((3.1415927410125732421875 * _9055) * _9055)) * (0.5 / max(mix((2.0 * _8925) * _8827, _8925 + _8827, _8818), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8925))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8925 * _8931));\n                }\n            }\n        }\n        if (_8866.on)\n        {\n            FaLayers param_54 = _8866;\n            vec3 param_55 = _8803;\n            vec3 param_56 = _8743;\n            vec3 param_57 = f0;\n            float param_58 = _8814;\n            float param_59 = _9493;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8803;\n            vec3 param_61 = _8743;\n            vec3 param_62 = f0;\n            float param_63 = _8814;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9493);\n        }\n        if (_8834 > 0.0)\n        {\n            float _9153;\n            if (_8866.on)\n            {\n                _9153 = _8866.f90;\n            }\n            else\n            {\n                _9153 = 1.0;\n            }\n            float _9161;\n            if (_8866.on)\n            {\n                _9161 = _8866.base_scale;\n            }\n            else\n            {\n                _9161 = 1.0;\n            }\n            Surface param_64 = Surface(_9488, _9489, _9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, _9498, _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507);\n            vec3 param_65 = _8803;\n            vec3 param_66 = _8743;\n            float param_67 = _8814;\n            vec3 param_68 = f0;\n            float param_69 = _9153;\n            float param_70 = _9161;\n            float param_71 = _8834;\n            float param_72 = fa_tr_blend;\n            vec3 _9185 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9185;\n        }\n        result = lit;\n    }\n    vec3 _9192 = result;\n    vec3 _9193 = _9192 + _9494;\n    result = _9193;\n    vec3 param_73 = _9193;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9202 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9209;\n    if (!_9202)\n    {\n        _9209 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9209 = _9202;\n    }\n    if (_9209)\n    {\n        vec3 _9218 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9224 = dot(_9218, fa_mesh_fs_params[9].xyz);\n        bool _9228 = fa_mesh_fs_params[9].w > 0.5;\n        float _9229;\n        if (_9228)\n        {\n            _9229 = _9224;\n        }\n        else\n        {\n            _9229 = length(_9218);\n        }\n        float _9241 = _9229 - fa_mesh_fs_params[8].x;\n        if (_9241 > 0.0)\n        {\n            float _9250 = fa_mesh_fs_params[7].w * _9241;\n            float tau = _9250 * _9250;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9266;\n                if (_9228)\n                {\n                    _9266 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9224);\n                }\n                else\n                {\n                    _9266 = fa_mesh_fs_params[0].y;\n                }\n                float _9287 = mix(_9266, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9229, 0.0, 1.0));\n                float _9291 = fa_world_pos.y - _9287;\n                float _9296 = _9287 - fa_mesh_fs_params[8].z;\n                float _9301 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9304 = _9296 <= 0.0;\n                bool _9305 = !_9304;\n                bool _9311;\n                if (_9305)\n                {\n                    _9311 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9311 = _9304;\n                }\n                float _9312;\n                if (_9311)\n                {\n                    _9312 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9312 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9296, 80.0));\n                }\n                bool _9339;\n                if (_9305)\n                {\n                    _9339 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9339 = _9304;\n                }\n                float _9340;\n                if (_9339)\n                {\n                    _9340 = fa_mesh_fs_params[8].y * _9296;\n                }\n                else\n                {\n                    _9340 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9296, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9365 = _9301 <= 0.0;\n                bool _9372;\n                if (!_9365)\n                {\n                    _9372 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9372 = _9365;\n                }\n                float _9373;\n                if (_9372)\n                {\n                    _9373 = fa_mesh_fs_params[8].y * _9301;\n                }\n                else\n                {\n                    _9373 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9301, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9400;\n                if (abs(_9291) < 0.001000000047497451305389404296875)\n                {\n                    _9400 = _9312;\n                }\n                else\n                {\n                    _9400 = (_9373 - _9340) / _9291;\n                }\n                tau += (_9241 * max(_9400, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9436 = 1.0 - fa_tr_blend;\n        result /= vec3(_9436);\n        _9489 *= _9436;\n    }\n    fa_frag_color = vec4(result, _9489);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_609",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2353",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8779",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _458 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_458, 1.0);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_458 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _270 = fa_tex_fix(param_2, param_3);\n    vec4 _890 = base_t;\n    _890.x = _270.x;\n    _890.y = _270.y;\n    _890.z = _270.z;\n    base_t = _890;\n    vec4 _286 = (_890 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _845 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _322 = fa_tex_fix(param_6, param_7);\n        vec3 _326 = (_322 * 2.0) - vec3(1.0);\n        vec2 _331 = _326.xy * fa_mesh_fs_params[6].x;\n        vec3 _898 = _326;\n        _898.x = _331.x;\n        _898.y = _331.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _898;\n        _845 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _362 = fa_tex_fix(param_12, param_13);\n    vec4 _901 = mrt;\n    _901.x = _362.x;\n    _901.y = _362.y;\n    _901.z = _362.z;\n    mrt = _901;\n    vec4 _394 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _394.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _406 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _438 = fa_tex_fix(param_20, param_21);\n    float _850 = fa_mesh_fs_params[20].x;\n    float _851 = fa_mesh_fs_params[20].y;\n    float _854 = fa_mesh_fs_params[20].z;\n    float _853 = fa_mesh_fs_params[21].w;\n    float _856 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _850 *= _406.y;\n            _851 *= _406.z;\n            _853 *= _394.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _854 *= mrt.x;\n            _856 *= mrt.w;\n        }\n    }\n    return Surface(_286.xyz, _286.w, _845, clamp(fa_mesh_fs_params[5].x * _362.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _362.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_406.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _438), _850, _851, fa_mesh_fs_params[21].xyz, _853, _854, fa_mesh_fs_params[20].w, _856, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _740 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _740 = -_740;\n    }\n    vec3 _589 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _740, fa_world_tangent, fa_uv, fa_vertex_color, _589, gl_FrontFacing);\n    Surface _594 = fa_standard_surface(param);\n    vec3 _764 = _594.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _740, fa_world_tangent, fa_uv, fa_vertex_color, _589, gl_FrontFacing);\n    Surface param_2 = _594;\n    surface(param_1, param_2);\n    _764 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    vec3 _616 = normalize(_764);\n    vec3 _631 = normalize(vec3(dot(fa_pre_r0, _616), dot(fa_pre_r1, _616), dot(fa_pre_r2, _616)));\n    float _643 = _631.z;\n    vec2 e = _631.xy / vec2((abs(_631.x) + abs(_631.y)) + abs(_643));\n    if (_643 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _687 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _694;\n    if (_687)\n    {\n        _694 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _694 = _687;\n    }\n    if (_694)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_57",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_225",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_605",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _723 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_723, 1.0);\n    fa_world_pos = _723;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_723 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _270 = fa_tex_fix(param_2, param_3);\n    vec4 _890 = base_t;\n    _890.x = _270.x;\n    _890.y = _270.y;\n    _890.z = _270.z;\n    base_t = _890;\n    vec4 _286 = (_890 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _845 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _322 = fa_tex_fix(param_6, param_7);\n        vec3 _326 = (_322 * 2.0) - vec3(1.0);\n        vec2 _331 = _326.xy * fa_mesh_fs_params[6].x;\n        vec3 _898 = _326;\n        _898.x = _331.x;\n        _898.y = _331.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _898;\n        _845 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _362 = fa_tex_fix(param_12, param_13);\n    vec4 _901 = mrt;\n    _901.x = _362.x;\n    _901.y = _362.y;\n    _901.z = _362.z;\n    mrt = _901;\n    vec4 _394 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _394.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _406 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _438 = fa_tex_fix(param_20, param_21);\n    float _850 = fa_mesh_fs_params[20].x;\n    float _851 = fa_mesh_fs_params[20].y;\n    float _854 = fa_mesh_fs_params[20].z;\n    float _853 = fa_mesh_fs_params[21].w;\n    float _856 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _850 *= _406.y;\n            _851 *= _406.z;\n            _853 *= _394.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _854 *= mrt.x;\n            _856 *= mrt.w;\n        }\n    }\n    return Surface(_286.xyz, _286.w, _845, clamp(fa_mesh_fs_params[5].x * _362.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _362.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_406.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _438), _850, _851, fa_mesh_fs_params[21].xyz, _853, _854, fa_mesh_fs_params[20].w, _856, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _740 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _740 = -_740;\n    }\n    vec3 _589 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _740, fa_world_tangent, fa_uv, fa_vertex_color, _589, gl_FrontFacing);\n    Surface _594 = fa_standard_surface(param);\n    vec3 _764 = _594.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _740, fa_world_tangent, fa_uv, fa_vertex_color, _589, gl_FrontFacing);\n    Surface param_2 = _594;\n    surface(param_1, param_2);\n    _764 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    vec3 _616 = normalize(_764);\n    vec3 _631 = normalize(vec3(dot(fa_pre_r0, _616), dot(fa_pre_r1, _616), dot(fa_pre_r2, _616)));\n    float _643 = _631.z;\n    vec2 e = _631.xy / vec2((abs(_631.x) + abs(_631.y)) + abs(_643));\n    if (_643 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _687 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _694;\n    if (_687)\n    {\n        _694 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _694 = _687;\n    }\n    if (_694)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_74",
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
            "inst_name": "_213",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_470",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_605",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
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
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
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
          }
        ]
      }
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _233 = _190.world_pos;\n    fa_world_pos = _233;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_233, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _733 = base_t;\n    _733.x = _230.x;\n    _733.y = _230.y;\n    _733.z = _230.z;\n    base_t = _733;\n    vec4 _246 = (_733 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _694 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _741 = _286;\n        _741.x = _291.x;\n        _741.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _741;\n        _694 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _744 = mrt;\n    _744.x = _322.x;\n    _744.y = _322.y;\n    _744.z = _322.z;\n    mrt = _744;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _699 = fa_mesh_fs_params[20].x;\n    float _700 = fa_mesh_fs_params[20].y;\n    float _703 = fa_mesh_fs_params[20].z;\n    float _702 = fa_mesh_fs_params[21].w;\n    float _705 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _699 *= _366.y;\n            _700 *= _366.z;\n            _702 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _703 *= mrt.x;\n            _705 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _694, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _699, _700, fa_mesh_fs_params[21].xyz, _702, _703, fa_mesh_fs_params[20].w, _705, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _589 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _589 = -_589;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _589, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _589, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_566",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
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
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_165 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_165 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_165 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vec3 _354 = _311.world_pos;\n    fa_world_pos = _354;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_354, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _733 = base_t;\n    _733.x = _230.x;\n    _733.y = _230.y;\n    _733.z = _230.z;\n    base_t = _733;\n    vec4 _246 = (_733 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _694 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _741 = _286;\n        _741.x = _291.x;\n        _741.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _741;\n        _694 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _744 = mrt;\n    _744.x = _322.x;\n    _744.y = _322.y;\n    _744.z = _322.z;\n    mrt = _744;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _699 = fa_mesh_fs_params[20].x;\n    float _700 = fa_mesh_fs_params[20].y;\n    float _703 = fa_mesh_fs_params[20].z;\n    float _702 = fa_mesh_fs_params[21].w;\n    float _705 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _699 *= _366.y;\n            _700 *= _366.z;\n            _702 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _703 *= mrt.x;\n            _705 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _694, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _699, _700, fa_mesh_fs_params[21].xyz, _702, _703, fa_mesh_fs_params[20].w, _705, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _589 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _589 = -_589;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _589, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _589, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
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
            "inst_name": "_174",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_566",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
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

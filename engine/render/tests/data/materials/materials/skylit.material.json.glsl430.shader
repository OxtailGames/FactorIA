{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "a2d4e04eb4f2eb60dbc4b204ae8b7d2a5340f65054070057cb4521c59a39bd38",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4657[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1433 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1440;\n    if (!_1433)\n    {\n        _1440 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1440 = _1433;\n    }\n    bool _1448;\n    if (!_1440)\n    {\n        _1448 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1448 = _1440;\n    }\n    bool _1455;\n    if (!_1448)\n    {\n        _1455 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1455 = _1448;\n    }\n    bool _1462;\n    if (!_1455)\n    {\n        _1462 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1462 = _1455;\n    }\n    if (_1462)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1472 = vec4(world_pos, 1.0);\n    float _1478 = dot(fa_mesh_fs_params[16], _1472);\n    if (!(_1478 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1500 = vec2(dot(fa_mesh_fs_params[14], _1472), dot(fa_mesh_fs_params[15], _1472)) / vec2(_1478);\n    int _1504 = int(fa_mesh_fs_params[18].x);\n    int _1508 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1508) + clamp(int(floor(((_1500.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1508 - 1)) * _1504)) + clamp(int(floor(((_1500.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1504 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1584 = fa_cluster_texel(param);\n    return ivec2(int(_1584.x), int(_1584.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5472 = fa_cluster_lookup(param);\n    fa_cl_slot = _5472.x;\n    fa_cl_local = _5472.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5684 = fa_linear_to_srgb(param);\n        c = _5684;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5692 = fa_srgb_to_linear(param_1);\n            c = _5692;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _387;\n    if (i.front_facing)\n    {\n        _387 = i.world_normal;\n    }\n    else\n    {\n        _387 = -i.world_normal;\n    }\n    vec3 _411 = normalize(i.world_tangent.xyz - (_387 * dot(_387, i.world_tangent.xyz)));\n    vec3 _438 = normalize(((_411 * m.x) + ((cross(_387, _411) * i.world_tangent.w) * m.y)) + (_387 * m.z));\n    vec3 _441;\n    if (i.front_facing)\n    {\n        _441 = _438;\n    }\n    else\n    {\n        _441 = -_438;\n    }\n    return _441;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5724 = fa_tex_fix(param_2, param_3);\n    vec4 _7637 = base_t;\n    _7637.x = _5724.x;\n    _7637.y = _5724.y;\n    _7637.z = _5724.z;\n    base_t = _7637;\n    vec4 _5738 = (_7637 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7422 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5772 = fa_tex_fix(param_6, param_7);\n        vec3 _5775 = (_5772 * 2.0) - vec3(1.0);\n        vec2 _5780 = _5775.xy * fa_mesh_fs_params[6].x;\n        vec3 _7645 = _5775;\n        _7645.x = _5780.x;\n        _7645.y = _5780.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7645;\n        _7422 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5810 = fa_tex_fix(param_12, param_13);\n    vec4 _7648 = mrt;\n    _7648.x = _5810.x;\n    _7648.y = _5810.y;\n    _7648.z = _5810.z;\n    mrt = _7648;\n    vec4 _5840 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5840.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5851 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5883 = fa_tex_fix(param_20, param_21);\n    float _7427 = fa_mesh_fs_params[20].x;\n    float _7428 = fa_mesh_fs_params[20].y;\n    float _7431 = fa_mesh_fs_params[20].z;\n    float _7430 = fa_mesh_fs_params[21].w;\n    float _7433 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7427 *= _5851.y;\n            _7428 *= _5851.z;\n            _7430 *= _5840.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7431 *= mrt.x;\n            _7433 *= mrt.w;\n        }\n    }\n    return Surface(_5738.xyz, _5738.w, _7422, clamp(fa_mesh_fs_params[5].x * _5810.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5810.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5851.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5883), _7427, _7428, fa_mesh_fs_params[21].xyz, _7430, _7431, fa_mesh_fs_params[20].w, _7433, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1664 = rect.zw - rect.xy;\n    vec2 _1668 = _1664 * atlas;\n    vec2 _1672 = ddx * _1668;\n    vec2 _1676 = ddy * _1668;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1664), clamp(0.5 * log2(max(max(dot(_1672, _1672), dot(_1676, _1676)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1709 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1716;\n    if (!_1709)\n    {\n        _1716 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1716 = _1709;\n    }\n    if (_1716)\n    {\n        return;\n    }\n    vec3 _1722 = dFdx(world_pos);\n    vec3 _1725 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1729 = fa_cluster_texel(param);\n    int _1733 = int(_1729.w);\n    if (_1733 < 1)\n    {\n        return;\n    }\n    int _1743 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1743;\n    vec4 _1747 = fa_light_texel(param_1);\n    vec2 _1750 = _1747.yz;\n    int _1754 = int(_1747.w);\n    int param_2 = _1743 + 1;\n    vec4 _1759 = fa_light_texel(param_2);\n    float _1760 = _1759.x;\n    int _1766 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1770 = int(_1729.z);\n    vec3 _2035;\n    for (int k = 0; k < _1733; k++)\n    {\n        int _1783 = _1770 + k;\n        int param_3 = _1754 + (_1783 >> 2);\n        int _1800 = (_1743 + 2) + (int(fa_light_texel(param_3)[_1783 & 3]) * 7);\n        int param_4 = _1800 + 6;\n        vec4 _1805 = fa_light_texel(param_4);\n        if (((int(_1805.w + 0.5) >> _1766) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1800;\n        vec4 _1820 = fa_light_texel(param_5);\n        int param_6 = _1800 + 1;\n        vec4 _1825 = fa_light_texel(param_6);\n        int param_7 = _1800 + 2;\n        vec4 _1830 = fa_light_texel(param_7);\n        vec3 _1833 = _1820.xyz;\n        float _1838 = dot(_1833, world_pos) + _1820.w;\n        vec3 _1840 = _1825.xyz;\n        float _1845 = dot(_1840, world_pos) + _1825.w;\n        vec3 _1847 = _1830.xyz;\n        float _1852 = dot(_1847, world_pos) + _1830.w;\n        bool _1857 = abs(_1838) > 0.5;\n        bool _1865;\n        if (!_1857)\n        {\n            _1865 = abs(_1845) > 0.5;\n        }\n        else\n        {\n            _1865 = _1857;\n        }\n        bool _1873;\n        if (!_1865)\n        {\n            _1873 = abs(_1852) > 0.5;\n        }\n        else\n        {\n            _1873 = _1865;\n        }\n        if (_1873)\n        {\n            continue;\n        }\n        float _1888 = clamp(dot(geo_normal, normalize(_1847)) * _1805.z, 0.0, 1.0);\n        if (_1888 <= 0.0)\n        {\n            continue;\n        }\n        float _1908 = (clamp((0.5 - abs(_1852)) * 10.0, 0.0, 1.0) * _1888) * _1805.x;\n        vec2 _1916 = vec2(_1838 + 0.5, 0.5 - _1845);\n        vec2 _1926 = vec2(dot(_1833, _1722), dot(_1840, _1722));\n        vec2 _1936 = vec2(dot(_1833, _1725), dot(_1840, _1725));\n        int param_8 = _1800 + 5;\n        vec4 _1941 = fa_light_texel(param_8);\n        int param_9 = _1800 + 3;\n        vec4 _1946 = fa_light_texel(param_9);\n        int param_10 = _1800 + 4;\n        vec4 _1951 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1941.xyz;\n        bool _1961 = _1946.z > _1946.x;\n        if (_1961)\n        {\n            vec4 param_11 = _1946;\n            vec2 param_12 = _1916;\n            vec2 param_13 = _1750;\n            vec2 param_14 = _1926;\n            vec2 param_15 = _1936;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1760 > 0.5) && (_1760 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1987 = fa_dc_to_linear(param_16);\n                vec4 _7510 = tx;\n                _7510.x = _1987.x;\n                _7510.y = _1987.y;\n                _7510.z = _1987.z;\n                tx = _7510;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1908 * tex_a) * _1941.w, 0.0, 1.0)));\n        if (_1951.z > _1951.x)\n        {\n            vec4 param_17 = _1951;\n            vec2 param_18 = _1916;\n            vec2 param_19 = _1750;\n            vec2 param_20 = _1926;\n            vec2 param_21 = _1936;\n            vec4 _2031 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1760 > 1.5)\n            {\n                vec3 param_22 = _2031.xyz;\n                vec3 _2041 = fa_dc_to_srgb(param_22);\n                _2035 = _2041;\n            }\n            else\n            {\n                _2035 = _2031.xyz;\n            }\n            vec3 _2050 = (_2035 * 2.0) - vec3(1.0);\n            vec2 _2055 = _2050.xy * _1805.y;\n            vec3 _2077 = (normalize(_1833) * _2055.x) + (normalize(_1840) * _2055.y);\n            vec3 _2080 = normalize(normal);\n            normal = normalize(mix(_2080, normalize((_2080 * max(_2050.z, 0.0500000007450580596923828125)) + (_2077 - (_2080 * dot(_2080, _2077)))), vec3(clamp(_1908 * (_1961 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3752 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3752;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4363 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4368 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4363 > 0.0005000000237487256526947021484375)\n    {\n        if (_4368)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4363;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4363;\n        }\n    }\n    bool _4419 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4419)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4450 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4450)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4368 || _4419) || _4450)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3772 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3775 = _3772.x;\n    float _3777 = _3772.z;\n    vec2 e = vec2(_3775, _3777);\n    if (_3772.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3777)) * ((_3775 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3775)) * ((_3777 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5995 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _6000 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _6005 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _6010 = fa_light_texel(param_3);\n    bool _6013 = _6010.z < 0.5;\n    bool _6021;\n    if (!_6013)\n    {\n        _6021 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _6021 = _6013;\n    }\n    if (_6021)\n    {\n        return vec3(0.0);\n    }\n    float _6028 = max(_5995.w, 9.9999997473787516355514526367188e-05);\n    vec3 _6031 = _6000.xyz;\n    vec3 _6035 = _5995.xyz;\n    vec3 _6039 = (fa_world_pos - _6035) / vec3(_6028);\n    vec3 _6048 = min(_6039 + vec3(0.5), (_6031 - vec3(0.5)) - _6039);\n    float _6057 = min(_6048.x, min(_6048.y, _6048.z));\n    if (!(_6057 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6072 = _6031 - vec3(1.0);\n    vec3 _6073 = clamp(_6039, vec3(0.0), _6072);\n    vec3 _6081 = min(floor(_6073), max(_6031 - vec3(2.0), vec3(0.0)));\n    vec3 _6085 = _6073 - _6081;\n    vec3 _6096 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _6028));\n    int _6101 = int(_6005.y + 0.5);\n    float _6106 = 0.3257350027561187744140625 * n.y;\n    float _6110 = 0.3257350027561187744140625 * n.z;\n    float _6114 = 0.3257350027561187744140625 * n.x;\n    float _6121 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _6128 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _6137 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _6144 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _6157 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _6164 = 8 + int(_6010.w);\n    float _6191;\n    float _6204;\n    float _6218;\n    for (int k = 0; k < _6164; k++)\n    {\n        float _6177 = float(k & 1);\n        float _6181 = float((k >> 1) & 1);\n        float _6185 = float((k >> 2) & 1);\n        if (_6177 > 0.5)\n        {\n            _6191 = _6085.x;\n        }\n        else\n        {\n            _6191 = 1.0 - _6085.x;\n        }\n        if (_6181 > 0.5)\n        {\n            _6204 = _6085.y;\n        }\n        else\n        {\n            _6204 = 1.0 - _6085.y;\n        }\n        if (_6185 > 0.5)\n        {\n            _6218 = _6085.z;\n        }\n        else\n        {\n            _6218 = 1.0 - _6085.z;\n        }\n        float _6228 = (_6191 * _6204) * _6218;\n        if (!(_6228 > 0.0))\n        {\n            continue;\n        }\n        vec3 _6241 = min(_6081 + vec3(_6177, _6181, _6185), _6072);\n        int _6261 = int(((_6005.x + _6241.x) + (_6000.x * (_6241.y + (_6000.y * _6241.z)))) + 0.5);\n        vec2 _6276 = vec2(float(_6261 % _6101) * 10.0, 1024.0 + (float(_6261 / _6101) * 11.0));\n        vec2 param_4 = _6276 + vec2(9.5, 10.5);\n        vec4 _6284 = fa_gi_fetch(param_4);\n        bool _6287 = _6284.y < 0.5;\n        bool _6296;\n        if (!_6287)\n        {\n            _6296 = _6284.x > _6010.y;\n        }\n        else\n        {\n            _6296 = _6287;\n        }\n        if (_6296)\n        {\n            continue;\n        }\n        vec3 _6308 = _6096 - (_6035 + (_6241 * _6028));\n        float _6311 = length(_6308);\n        vec3 _6317 = _6308 / vec3(max(_6311, 9.9999997473787516355514526367188e-05));\n        float _6327 = max(9.9999997473787516355514526367188e-05, (dot(-_6317, n) + 1.0) * 0.5);\n        float w = _6228 * (_6327 * _6327);\n        vec3 param_5 = _6317;\n        vec2 param_6 = (_6276 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _6346 = fa_gi_fetch(param_6);\n        float _6353 = _6311 / max(_6005.z, 9.9999997473787516355514526367188e-05);\n        float _6356 = _6346.x;\n        if (_6353 > _6356)\n        {\n            float _6369 = max(_6346.y - (_6356 * _6356), 0.0);\n            float _6374 = _6353 - _6356;\n            float _6383 = _6369 / max(_6369 + (_6374 * _6374), 9.9999999600419720025001879548654e-13);\n            w *= ((_6383 * _6383) * _6383);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _6276 + vec2(0.5, 10.5);\n        vec2 param_8 = _6276 + vec2(1.5, 10.5);\n        vec2 param_9 = _6276 + vec2(2.5, 10.5);\n        vec2 param_10 = _6276 + vec2(3.5, 10.5);\n        vec2 param_11 = _6276 + vec2(4.5, 10.5);\n        vec2 param_12 = _6276 + vec2(5.5, 10.5);\n        vec2 param_13 = _6276 + vec2(6.5, 10.5);\n        vec2 param_14 = _6276 + vec2(7.5, 10.5);\n        vec2 param_15 = _6276 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _6106)) + (fa_gi_fetch(param_9).xyz * _6110)) + (fa_gi_fetch(param_10).xyz * _6114)) + (fa_gi_fetch(param_11).xyz * _6121)) + (fa_gi_fetch(param_12).xyz * _6128)) + (fa_gi_fetch(param_13).xyz * _6137)) + (fa_gi_fetch(param_14).xyz * _6144)) + (fa_gi_fetch(param_15).xyz * _6157)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_6057 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6509;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6509 = _6010.x;\n    }\n    else\n    {\n        _6509 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_6005.w * _6509);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6533 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6538 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6543 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6543) && (k < 8); k++)\n    {\n        int param = _6538 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6533;\n        vec3 _6568 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6573 = param_3 * left;\n        acc += (_6568 * _6573);\n        left -= _6573;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6602 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6602;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4582 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4590 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4593 = int(_4582);\n    int _4596 = int(_4590);\n    float _4606 = _4590 - float(_4596);\n    int _4661 = (_4593 * 9) + _4596;\n    int _4681 = ((_4593 + 1) * 9) + _4596;\n    return mix(mix(_4657[_4661], _4657[_4661 + 1], _4606), mix(_4657[_4681], _4657[_4681 + 1], _4606), _4582 - float(_4593));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7281 = false;\n    float _7282 = 1.0;\n    float _7283 = 1.0;\n    float _7284 = 1.0;\n    float _7285 = 0.0;\n    float _7286 = 0.0;\n    float _7287 = 0.0;\n    float _7288 = 0.0;\n    float _7290 = 1.0;\n    bool _7291 = false;\n    vec3 _7292 = vec3(0.0);\n    float _7293 = 1.0;\n    float _7294 = 1.0;\n    float _7295 = 1.0;\n    float _7296 = 0.0;\n    float _7297 = 0.0;\n    vec3 _7298 = vec3(1.0, 0.0, 0.0);\n    vec3 _7299 = vec3(0.0, 0.0, 1.0);\n    float _7300 = 1.0;\n    float _7301 = 1.0;\n    float _4732 = clamp(s.specular, 0.0, 1.0);\n    float _4736 = clamp(s.ior, 1.0, 3.0);\n    bool _4741 = (_4732 != 1.0) || (_4736 != 1.5);\n    bool _4750;\n    if (!_4741)\n    {\n        _4750 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4750 = _4741;\n    }\n    if (_4750)\n    {\n        float _4758 = (_4736 - 1.0) / (_4736 + 1.0);\n        f0 = mix(min(vec3(_4758 * _4758) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4732, s.albedo, vec3(metallic));\n        _7282 = mix(_4732, 1.0, metallic);\n        _7281 = true;\n    }\n    float _4785 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4785 > 0.0)\n    {\n        float _4793 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7285 = _4785;\n        _7286 = _4793;\n        float _4800 = _4793 * _4793;\n        _7287 = _4800;\n        _7288 = _4800 * _4800;\n        float _4812 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7290 = _4812;\n        _7283 = 1.0 - (_4785 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4812, 0.0, 1.0), 5.0))));\n        _7281 = true;\n    }\n    vec3 _4831 = max(s.sheen_color, vec3(0.0));\n    float _4840 = max(_4831.x, max(_4831.y, _4831.z));\n    if (_4840 > 0.0)\n    {\n        float _4848 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7291 = true;\n        _7292 = _4831;\n        _7293 = _4848;\n        _7294 = _4848 * _4848;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4848;\n        float _4865 = fa_sheen_albedo(param, param_1);\n        _7296 = _4865;\n        _7295 = 1.0 - min(_4840 * _4865, 1.0);\n        _7281 = true;\n    }\n    _7284 = _7283 * _7295;\n    float _4884 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4884 != 0.0)\n    {\n        vec3 _4899 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4899;\n        if (dot(_4899, _4899) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4911 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4911.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4911.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4911.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4915 = t;\n        vec3 _4916 = normalize(_4915);\n        t = _4916;\n        vec3 _4941 = normalize((_4916 * cos(s.anisotropy_rotation)) + ((cross(n, _4916) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7298 = _4941;\n        _7299 = cross(n, _4941);\n        float _4951 = roughness * roughness;\n        float _4957 = mix(_4951, 1.0, _4884 * _4884);\n        bool _4959 = _4884 > 0.0;\n        _7300 = _4959 ? _4957 : _4951;\n        _7301 = _4959 ? _4951 : _4957;\n        _7297 = _4884;\n        _7281 = true;\n    }\n    return FaLayers(_7281, _7282, _7283, _7284, _7285, _7286, _7287, _7288, i.world_normal, _7290, _7291, _7292, _7293, _7294, _7295, _7296, _7297, _7298, _7299, _7300, _7301);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4514 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4517 = _4514.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4517 * _4517, exp2((-9.27999973297119140625) * ndv)) * _4517) + _4514.y)) + _4514.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3824;\n    if (lv == 0)\n    {\n        _3824 = 0.0;\n    }\n    else\n    {\n        _3824 = res + 2.0;\n    }\n    float _3834;\n    if (lv == 0)\n    {\n        _3834 = 0.0;\n    }\n    else\n    {\n        _3834 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3824, _3834)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3880;\n    if (res > 64.5)\n    {\n        _3880 = 5.0;\n    }\n    else\n    {\n        _3880 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3895 = clamp(rough, 0.0, 1.0) * (_3880 - 1.0);\n    int _3902 = int(min(floor(_3895), _3880 - 2.0));\n    float _3907 = _3895 - float(_3902);\n    vec3 param = d;\n    vec2 _3911 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3902;\n    vec2 param_4 = _3911;\n    vec3 _3921 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3907 < 0.00200000009499490261077880859375)\n    {\n        return _3921;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3902 + 1;\n    vec2 param_8 = _3911;\n    return mix(_3921, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3907));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3992 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3999 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4006 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4012 = dot(bx.xyz, d);\n    float _4016 = dot(by.xyz, d);\n    float _4020 = dot(bz.xyz, d);\n    float _4026;\n    if (_4012 > 9.9999999747524270787835121154785e-07)\n    {\n        _4026 = (1.0 - _3992) / _4012;\n    }\n    else\n    {\n        float _4040;\n        if (_4012 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4040 = ((-1.0) - _3992) / _4012;\n        }\n        else\n        {\n            _4040 = 1000000015047466219876688855040.0;\n        }\n        _4026 = _4040;\n    }\n    float tx = _4026;\n    float _4057;\n    if (_4016 > 9.9999999747524270787835121154785e-07)\n    {\n        _4057 = (1.0 - _3999) / _4016;\n    }\n    else\n    {\n        float _4070;\n        if (_4016 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4070 = ((-1.0) - _3999) / _4016;\n        }\n        else\n        {\n            _4070 = 1000000015047466219876688855040.0;\n        }\n        _4057 = _4070;\n    }\n    float ty = _4057;\n    float _4086;\n    if (_4020 > 9.9999999747524270787835121154785e-07)\n    {\n        _4086 = (1.0 - _4006) / _4020;\n    }\n    else\n    {\n        float _4099;\n        if (_4020 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4099 = ((-1.0) - _4006) / _4020;\n        }\n        else\n        {\n            _4099 = 1000000015047466219876688855040.0;\n        }\n        _4086 = _4099;\n    }\n    float _4111 = tx;\n    float _4114 = (_4111 > 0.0) ? _4111 : 1000000015047466219876688855040.0;\n    tx = _4114;\n    float _4115 = ty;\n    float _4118 = (_4115 > 0.0) ? _4115 : 1000000015047466219876688855040.0;\n    ty = _4118;\n    float _4128 = min(_4114, min(_4118, (_4086 > 0.0) ? _4086 : 1000000015047466219876688855040.0));\n    if (_4128 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4144 = (fa_world_pos + (d * _4128)) - posw.xyz;\n    vec3 _4149;\n    if (dot(_4144, _4144) > 1.0000000133514319600180897396058e-10)\n    {\n        _4149 = normalize(_4144);\n    }\n    else\n    {\n        _4149 = d;\n    }\n    return _4149;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4195 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4195 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4223 = rough * rough;\n            float _4254 = 0.60000002384185791015625 * _4223;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4223)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4254, 0.0500000007450580596923828125 + _4254, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4223 * 0.60000002384185791015625));\n        }\n        outc = base * _4195;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4313 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4313 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4345 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4345 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4992;\n        if (L.aniso >= 0.0)\n        {\n            _4992 = L.b;\n        }\n        else\n        {\n            _4992 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4992, v), _4992), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5028 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5028.x) + (vec3(L.f90) * _5028.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5086 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5086.x) + _5086.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4556 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4556.x) + vec3(_4556.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _5115 = clamp(s.metallic, 0.0, 1.0);\n    float _5119 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _5126 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_5115));\n    vec3 f0 = _5126;\n    vec3 _5130 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _5130;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _5115;\n    float param_5 = _5119;\n    vec3 param_6 = _5126;\n    FaLayers _5147 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_5147.on)\n    {\n        FaLayers param_7 = _5147;\n        vec3 param_8 = _5130;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _5119;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _5130;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _5119;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5442;\n    if (fa_lm.z > 0.5)\n    {\n        _5442 = 0.0;\n    }\n    else\n    {\n        _5442 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5453 = _5442 < 1.0;\n    bool _5459;\n    if (_5453)\n    {\n        int param = li;\n        _5459 = fa_light_baked(param);\n    }\n    else\n    {\n        _5459 = _5453;\n    }\n    return _5459 ? _5442 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _683 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _696 = (c - (ru * hx)) - p;\n        vec3 _702 = ru * (2.0 * hx);\n        float _708 = max(dot(_702, _702), 9.9999999392252902907785028219223e-09);\n        float _712 = dot(_696, _702);\n        float t = clamp((-_712) / _708, 0.0, 1.0);\n        if (_683)\n        {\n            float _727 = dot(r, _702);\n            float _733 = _708 - (_727 * _727);\n            if (abs(_733) > (9.9999997473787516355514526367188e-06 * _708))\n            {\n                t = clamp(((dot(r, _696) * _727) - _712) / _733, 0.0, 1.0);\n            }\n        }\n        return (p + _696) + (_702 * t);\n    }\n    vec3 q = p;\n    float _765 = dot(r, axis);\n    bool _773;\n    if (_683)\n    {\n        _773 = abs(_765) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _773 = _683;\n    }\n    if (_773)\n    {\n        float _783 = dot(c - p, axis) / _765;\n        if (_783 > 0.0)\n        {\n            q = p + (r * _783);\n        }\n    }\n    vec3 _796 = q - c;\n    vec2 xy = vec2(dot(_796, ru), dot(_796, uu));\n    if (shape > 0.5)\n    {\n        float _811 = length(xy);\n        if (_811 > hx)\n        {\n            xy *= (hx / _811);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _603 = dot(d, right);\n    float _607 = dot(d, up);\n    float _618;\n    if (((_603 * _603) + (_607 * _607)) > 1.0000000133514319600180897396058e-10)\n    {\n        _618 = atan(_607, _603) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _618 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_618 - floor(_618)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _453 = abs(d);\n    float _455 = _453.x;\n    float _457 = _453.y;\n    bool _458 = _455 >= _457;\n    bool _466;\n    if (_458)\n    {\n        _466 = _455 >= _453.z;\n    }\n    else\n    {\n        _466 = _458;\n    }\n    int _467;\n    if (_466)\n    {\n        _467 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _482;\n        if (_457 >= _453.z)\n        {\n            _482 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _482 = (d.z > 0.0) ? 4 : 5;\n        }\n        _467 = _482;\n    }\n    return _467;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _849 = fa_light_base(param);\n    bool _853 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _849;\n    vec4 _857 = fa_light_texel(param_1);\n    int param_2 = _849 + 1;\n    vec4 _862 = fa_light_texel(param_2);\n    float _865 = _862.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _877 = _853 && (_865 > 2.5);\n    fa_light_is_area = _877;\n    bool _879 = _865 < 0.5;\n    vec3 l;\n    if (_879)\n    {\n        l = normalize(_857.xyz);\n        if (_853)\n        {\n            int param_3 = _849 + 6;\n            vec4 _893 = fa_light_texel(param_3);\n            if (_893.z > 0.5)\n            {\n                int param_4 = _849 + 4;\n                vec4 _903 = fa_light_texel(param_4);\n                int param_5 = _849 + 5;\n                vec4 _908 = fa_light_texel(param_5);\n                vec2 param_6 = _893.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _903.xyz) * _903.w, (-dot(world_pos, _908.xyz)) * _908.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _938 = _857.xyz;\n        vec3 _940 = _938 - world_pos;\n        vec3 to_light = _940;\n        float _943 = length(_940);\n        float reach = _943;\n        bool front = true;\n        if (_877)\n        {\n            int param_8 = _849 + 7;\n            reach = max(_943 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _849 + 4;\n            vec4 _967 = fa_light_texel(param_9);\n            int param_10 = _849 + 5;\n            vec4 _972 = fa_light_texel(param_10);\n            int param_11 = _849 + 6;\n            vec4 _977 = fa_light_texel(param_11);\n            float _978 = _977.w;\n            int param_12 = _849 + 2;\n            vec3 _985 = normalize(fa_light_texel(param_12).xyz);\n            bool _987 = _978 > 1.5;\n            bool _995;\n            if (!_987)\n            {\n                _995 = dot(_985, to_light) < 0.0;\n            }\n            else\n            {\n                _995 = _987;\n            }\n            front = _995;\n            vec3 r = vec3(0.0);\n            vec3 _1004 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1008 = dot(n, n) > 0.5;\n            bool _1016;\n            if (_1008)\n            {\n                _1016 = dot(_1004, _1004) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1016 = _1008;\n            }\n            if (_1016)\n            {\n                r = reflect(-normalize(_1004), normalize(n));\n            }\n            vec3 param_13 = _938;\n            vec3 param_14 = _985;\n            vec3 param_15 = _967.xyz;\n            vec3 param_16 = _972.xyz;\n            float param_17 = _967.w;\n            float param_18 = _972.w;\n            float param_19 = _978;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1052 = length(to_light);\n        dist = _1052;\n        l = to_light / vec3(max(_1052, 9.9999997473787516355514526367188e-05));\n        float _1066 = reach / max(_857.w, 0.001000000047497451305389404296875);\n        float _1072 = clamp(1.0 - (_1066 * _1066), 0.0, 1.0);\n        float _1074;\n        if (front)\n        {\n            _1074 = _1072 * _1072;\n        }\n        else\n        {\n            _1074 = 0.0;\n        }\n        atten = _1074;\n        bool _1085 = _865 < 2.5;\n        if ((_865 > 1.5) && _1085)\n        {\n            int param_22 = _849 + 2;\n            vec4 _1093 = fa_light_texel(param_22);\n            float _1103 = _1093.w;\n            int param_23 = _849 + 3;\n            vec4 _1108 = fa_light_texel(param_23);\n            float _1109 = _1108.x;\n            float cos_inner = _1109;\n            if (_1109 > 1.5)\n            {\n                cos_inner = mix(_1103, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1103, cos_inner, dot(-l, normalize(_1093.xyz)));\n        }\n        if (_853 && (_865 < 1.5))\n        {\n            int param_24 = _849 + 6;\n            vec4 _1133 = fa_light_texel(param_24);\n            if (_1133.z > 0.5)\n            {\n                vec3 _1141 = -to_light;\n                int param_25 = _849 + 4;\n                int param_26 = _849 + 5;\n                vec3 _1155 = fa_light_texel(param_25).xyz;\n                vec3 _1159 = fa_light_texel(param_26).xyz;\n                vec3 _1168 = vec3(dot(_1141, _1155), dot(_1141, _1159), dot(_1141, cross(_1155, _1159)));\n                vec3 param_27 = _1168;\n                int _1172 = fa_cube_face(param_27);\n                int param_28 = _1172;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1199 = vec2(dot(_1168, cross(param_29, param_30)), dot(_1168, param_30)) / vec2(max(dot(_1168, param_29), 9.9999997473787516355514526367188e-05));\n                int _1203 = _1172 / 3;\n                vec2 param_31 = _1133.xy + (vec2(float(_1172 - (_1203 * 3)), float(_1203)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1199.x), 0.5 - (0.5 * _1199.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _849 + 7;\n            vec4 _1233 = fa_light_texel(param_33);\n            if (_1233.z > 0.5)\n            {\n                int param_34 = _849 + 2;\n                int param_35 = _849 + 4;\n                int param_36 = _849 + 5;\n                vec2 param_37 = _1233.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_853 && _1085)\n            {\n                int param_42 = _849 + 6;\n                vec4 _1280 = fa_light_texel(param_42);\n                int param_43 = _849 + 7;\n                vec4 _1285 = fa_light_texel(param_43);\n                bool _1288 = _1280.z > 0.5;\n                bool _1295;\n                if (!_1288)\n                {\n                    _1295 = _1285.z > 0.5;\n                }\n                else\n                {\n                    _1295 = _1288;\n                }\n                if (_1295)\n                {\n                    int param_44 = _849 + 2;\n                    vec4 _1302 = fa_light_texel(param_44);\n                    vec3 _1306 = normalize(_1302.xyz);\n                    int param_45 = _849 + 4;\n                    vec4 _1311 = fa_light_texel(param_45);\n                    int param_46 = _849 + 5;\n                    vec4 _1316 = fa_light_texel(param_46);\n                    if (_1288)\n                    {\n                        vec3 _1324 = -to_light;\n                        float _1331 = _1302.w;\n                        float _1347 = 0.5 / max(dot(_1324, _1306) * (sqrt(max(1.0 - (_1331 * _1331), 0.0)) / max(_1331, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1280.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1324, _1311.xyz) * _1347), 0.5 - (dot(_1324, _1316.xyz) * _1347));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1285.z > 0.5)\n                    {\n                        vec2 param_49 = _1285.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1306;\n                        vec3 param_52 = _1311.xyz;\n                        vec3 param_53 = _1316.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7269 = _862.xyz * atten;\n    if (_853)\n    {\n        _7269 *= fa_light_tint;\n    }\n    int _1415;\n    if (_879)\n    {\n        _1415 = 0;\n    }\n    else\n    {\n        _1415 = ((_865 > 1.5) && (_865 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7269, atten, 1.0, dist, _1415);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2204 = fa_shadow_depth(param, param_1);\n    float _2208;\n    if (conv.x < 0.5)\n    {\n        _2208 = _2204;\n    }\n    else\n    {\n        _2208 = (conv.y * conv.z) / (conv.z - (_2204 * (conv.z - conv.y)));\n    }\n    return _2208;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2254 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2260 = vec2(cos(_2254), sin(_2254));\n    vec2 dir = _2260;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2269;\n        if (k < 0.0)\n        {\n            _2269 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2269 = k;\n        }\n        float _2288 = clamp((_2269 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2307 = sqrt((float(i) + 0.5) * 0.0625) * _2288;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2307));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2321 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2321 < (zr - (_2307 * plane)))\n            {\n                sum += _2321;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2349 = sum / cnt;\n        float _2359;\n        if (k < 0.0)\n        {\n            _2359 = (-k) / max(_2349, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2359 = k;\n        }\n        radius = clamp(((max(zr - _2349, 0.0) * unit) * _2359) / texel_m, 1.5, 16.0);\n        dir = _2260;\n    }\n    float lit = 0.0;\n    int _2385 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2385; i_1++)\n    {\n        float _2404 = sqrt((float(i_1) + 0.5) / float(_2385)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2404));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2404 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2385);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2609 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2616;\n    if (!_2609)\n    {\n        _2616 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2616 = _2609;\n    }\n    if (_2616)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2629 = fa_light_texel(param);\n    float _2630 = _2629.x;\n    if (_2630 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2639 = int(_2630 + 0.5);\n    int param_1 = _2639;\n    vec4 _2643 = fa_light_texel(param_1);\n    int param_2 = _2639 + 1;\n    vec4 _2648 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2651 = _2643.y;\n    if (_2651 > 0.0)\n    {\n        float _2668 = 1.0 - smoothstep(0.75 * _2651, _2651, length(world - fa_shadows[27].xyz));\n        fade = _2668;\n        if (_2668 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2643.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2692 = (_2639 + 2) + (face * 6);\n    int param_4 = _2692;\n    int param_5 = _2692 + 1;\n    int param_6 = _2692 + 3;\n    vec4 _2706 = fa_light_texel(param_6);\n    int param_7 = _2692 + 4;\n    vec4 _2711 = fa_light_texel(param_7);\n    int param_8 = _2692 + 5;\n    vec4 _2716 = fa_light_texel(param_8);\n    float _2728 = _2716.x * max(dot(_2706, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2733 = clamp(dot(n, l), 0.0, 1.0);\n    float _2756 = clamp(dot(n, _2706.xyz), -1.0, 1.0);\n    float _2775 = min(sqrt(1.0 - (_2756 * _2756)) / max(abs(dot(n, world - lpos)) / max(dot(_2706, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2778 = _2648.y;\n    float _2780;\n    if (_2778 > 0.0)\n    {\n        _2780 = _2778;\n    }\n    else\n    {\n        _2780 = 1.5 * _2728;\n    }\n    vec4 _2800 = vec4(world + (n * (_2780 * sqrt(1.0 - (_2733 * _2733)))), 1.0);\n    float _2804 = dot(_2706, _2800);\n    float _2807 = _2716.y;\n    if (_2804 < _2807)\n    {\n        return 1.0;\n    }\n    vec2 _2822 = vec2(dot(fa_light_texel(param_4), _2800), dot(fa_light_texel(param_5), _2800)) / vec2(_2804);\n    float _2824 = _2822.x;\n    bool _2827 = _2824 < _2711.x;\n    bool _2836;\n    if (!_2827)\n    {\n        _2836 = _2824 > _2711.z;\n    }\n    else\n    {\n        _2836 = _2827;\n    }\n    bool _2845;\n    if (!_2836)\n    {\n        _2845 = _2822.y < _2711.y;\n    }\n    else\n    {\n        _2845 = _2836;\n    }\n    bool _2854;\n    if (!_2845)\n    {\n        _2854 = _2822.y > _2711.w;\n    }\n    else\n    {\n        _2854 = _2845;\n    }\n    if (_2854)\n    {\n        return 1.0;\n    }\n    float _2860 = _2648.x;\n    float _2862;\n    if (_2860 > 0.0)\n    {\n        _2862 = _2860;\n    }\n    else\n    {\n        _2862 = 1.5 * _2728;\n    }\n    vec2 param_9 = _2822;\n    vec4 param_10 = _2711;\n    float param_11 = _2804 - (_2862 * (1.0 + (0.5 * _2775)));\n    float param_12 = _2728;\n    float param_13 = 1.0;\n    float param_14 = _2716.z * 0.25;\n    float param_15 = (_2728 * min(_2775, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2807, _2716.z);\n    int param_17 = int(_2643.z + 0.5);\n    float param_18 = _2643.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3374 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3380;\n    if (_3374)\n    {\n        _3380 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3380 = _3374;\n    }\n    bool _3386;\n    if (_3380)\n    {\n        _3386 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3386 = _3380;\n    }\n    if (_3386)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3398 = fa_light_texel(param);\n        float _3399 = _3398.z;\n        if (_3399 > 0.5)\n        {\n            float _3412 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3415 = fwidth(_3412);\n            float _3419 = min(1.5 * _3415, 0.100000001490116119384765625 * _3412);\n            vec4 _3425 = vec4(world, 1.0);\n            float _3430 = dot(fa_mesh_fs_params[28], _3425);\n            if (_3430 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3447 = vec2(dot(fa_mesh_fs_params[26], _3425), dot(fa_mesh_fs_params[27], _3425)) / vec2(_3430);\n                float _3452 = (_3447.x * 0.5) + 0.5;\n                float _3456;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3456 = (_3447.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3456 = 0.5 - (_3447.y * 0.5);\n                }\n                bool _3472 = _3452 >= 0.0;\n                bool _3478;\n                if (_3472)\n                {\n                    _3478 = _3452 < 1.0;\n                }\n                else\n                {\n                    _3478 = _3472;\n                }\n                bool _3484;\n                if (_3478)\n                {\n                    _3484 = _3456 >= 0.0;\n                }\n                else\n                {\n                    _3484 = _3478;\n                }\n                bool _3490;\n                if (_3484)\n                {\n                    _3490 = _3456 < 1.0;\n                }\n                else\n                {\n                    _3490 = _3484;\n                }\n                if (_3490)\n                {\n                    ivec2 _3507 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3508 = clamp(ivec2(vec2(_3452, _3456) * fa_mesh_fs_params[24].zw), ivec2(0), _3507);\n                    ivec2 _3520;\n                    ivec2 _3526;\n                    ivec2 _3533;\n                    float _3584;\n                    float _3605;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3520 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3526 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3533 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3544 = bvec2(k == 3);\n                                    _3533 = ivec2(_3544.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3544.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3526 = _3533;\n                            }\n                            _3520 = _3526;\n                        }\n                        vec4 _3561 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3508 + _3520, ivec2(0), _3507), 0);\n                        bool _3564 = _3561.w > 0.5;\n                        bool _3578;\n                        if (_3564)\n                        {\n                            _3578 = abs(_3412 - _3561.x) <= (((0.00200000009499490261077880859375 * _3412) + 0.00999999977648258209228515625) + _3419);\n                        }\n                        else\n                        {\n                            _3578 = _3564;\n                        }\n                        if (_3578)\n                        {\n                            if (_3399 < 1.5)\n                            {\n                                _3584 = 1.0;\n                            }\n                            else\n                            {\n                                _3584 = (_3399 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3601 = mod(floor(_3561.z / _3584), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3605 = min(_3601, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3605 = _3601;\n                            }\n                            return _3605;\n                        }\n                    }\n                }\n            }\n            float _3630;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3630 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3630 = 1.0;\n            }\n            return _3630;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2147;\n    if (i == 0)\n    {\n        _2147 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2163;\n        if (i == 1)\n        {\n            _2163 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2171;\n            if (i == 2)\n            {\n                _2171 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2171 = fa_shadows[24].w;\n            }\n            _2163 = _2171;\n        }\n        _2147 = _2163;\n    }\n    return _2147;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2450 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2455 = clamp(dot(n, l), 0.0, 1.0);\n    float _2461 = sqrt(1.0 - (_2455 * _2455));\n    float _2469 = min(_2461 / max(_2455, 0.20000000298023223876953125), 4.0);\n    float _2474;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2474 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2474 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2499 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2474 * _2461)), 1.0);\n    float _2506 = _2499.x;\n    bool _2509 = _2506 < fa_shadows[ci * 1 + 16].x;\n    bool _2518;\n    if (!_2509)\n    {\n        _2518 = _2506 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2518 = _2509;\n    }\n    bool _2527;\n    if (!_2518)\n    {\n        _2527 = _2499.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2527 = _2518;\n    }\n    bool _2536;\n    if (!_2527)\n    {\n        _2536 = _2499.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2536 = _2527;\n    }\n    bool _2543;\n    if (!_2536)\n    {\n        _2543 = _2499.z > 1.0;\n    }\n    else\n    {\n        _2543 = _2536;\n    }\n    if (_2543)\n    {\n        return -1.0;\n    }\n    float _2551;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2551 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2551 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2499.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2499.z - ((_2551 * (1.0 + (0.5 * _2469))) / _2450);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2450;\n    float param_5 = _2450 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2469, 3.0)) * 0.5) / _2450;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2929 = int(fa_shadows[25].x + 0.5);\n    if (_2929 < 1)\n    {\n        return 1.0;\n    }\n    float _2944 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2929 - 1;\n    if (_2944 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2956 = _2929 > 1;\n    bool _2963;\n    if (_2956)\n    {\n        _2963 = _2944 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2963 = _2956;\n    }\n    if (_2963)\n    {\n        ci = 1;\n    }\n    bool _2967 = _2929 > 2;\n    bool _2974;\n    if (_2967)\n    {\n        _2974 = _2944 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2974 = _2967;\n    }\n    if (_2974)\n    {\n        ci = 2;\n    }\n    bool _2978 = _2929 > 3;\n    bool _2985;\n    if (_2978)\n    {\n        _2985 = _2944 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2985 = _2978;\n    }\n    if (_2985)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2996 = min(_2929, 4);\n    float _3037;\n    for (int c = ci; c < _2996; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3016 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3016;\n            break;\n        }\n        if (_3016 < 0.0)\n        {\n            continue;\n        }\n        s = _3016;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3037 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3037 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3056 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3037, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2944 - (fa_shadow_split_at(param_7) - _3056)) / _3056, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3088;\n        if ((ci + 1) < _2929)\n        {\n            _3088 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3088 = 1.0;\n        }\n        s = mix(s, _3088, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3193 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3199;\n    if (_3193)\n    {\n        _3199 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3199 = _3193;\n    }\n    if (_3199)\n    {\n        float _3213 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3216 = fwidth(_3213);\n        vec4 _3226 = vec4(fa_world_pos, 1.0);\n        float _3232 = dot(fa_mesh_fs_params[28], _3226);\n        if (_3232 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3251 = vec2(dot(fa_mesh_fs_params[26], _3226), dot(fa_mesh_fs_params[27], _3226)) / vec2(_3232);\n            float _3256 = (_3251.x * 0.5) + 0.5;\n            float _3260;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3260 = (_3251.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3260 = 0.5 - (_3251.y * 0.5);\n            }\n            bool _3276 = _3256 >= 0.0;\n            bool _3282;\n            if (_3276)\n            {\n                _3282 = _3256 < 1.0;\n            }\n            else\n            {\n                _3282 = _3276;\n            }\n            bool _3288;\n            if (_3282)\n            {\n                _3288 = _3260 >= 0.0;\n            }\n            else\n            {\n                _3288 = _3282;\n            }\n            bool _3294;\n            if (_3288)\n            {\n                _3294 = _3260 < 1.0;\n            }\n            else\n            {\n                _3294 = _3288;\n            }\n            if (_3294)\n            {\n                vec4 _3320 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3256, _3260) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3323 = _3320.w > 0.5;\n                bool _3339;\n                if (_3323)\n                {\n                    _3339 = abs(_3213 - _3320.x) <= (((0.00200000009499490261077880859375 * _3213) + 0.00999999977648258209228515625) + min(1.5 * _3216, 0.100000001490116119384765625 * _3213));\n                }\n                else\n                {\n                    _3339 = _3323;\n                }\n                if (_3339)\n                {\n                    float _3345;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3345 = min(_3320.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3345 = _3320.y;\n                    }\n                    return _3345;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5186 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5193;\n    if (!_5186)\n    {\n        _5193 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5193 = _5186;\n    }\n    if (_5193)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5206 = fa_light_texel(param);\n    float _5207 = _5206.y;\n    float len = _5207;\n    if (_5207 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5219 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5228 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5219);\n    if (_5228 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5234 = len;\n    float _5237 = min(_5234, 0.89999997615814208984375 * dist);\n    len = _5237;\n    float _5242 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5219);\n    float _5247 = _5242 + (0.5 * _5237);\n    vec3 _5253 = world + (gn * _5242);\n    float _5255 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5316;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5270 = (float(k) + _5255) * 0.083333335816860198974609375;\n        vec3 _5278 = _5253 + (l * (_5270 * len));\n        vec4 _5284 = vec4(_5278, 1.0);\n        float _5289 = dot(fa_mesh_fs_params[28], _5284);\n        if (_5289 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5307 = vec2(dot(fa_mesh_fs_params[26], _5284), dot(fa_mesh_fs_params[27], _5284)) / vec2(_5289);\n        float _5311 = _5307.x * 0.5;\n        float _5312 = _5311 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5316 = (_5307.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5316 = 0.5 - (_5307.y * 0.5);\n        }\n        bool _5332 = _5312 < 0.0;\n        bool _5339;\n        if (!_5332)\n        {\n            _5339 = _5312 >= 1.0;\n        }\n        else\n        {\n            _5339 = _5332;\n        }\n        bool _5346;\n        if (!_5339)\n        {\n            _5346 = _5316 < 0.0;\n        }\n        else\n        {\n            _5346 = _5339;\n        }\n        bool _5353;\n        if (!_5346)\n        {\n            _5353 = _5316 >= 1.0;\n        }\n        else\n        {\n            _5353 = _5346;\n        }\n        if (_5353)\n        {\n            break;\n        }\n        vec4 _5377 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5312, _5316) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5377.w < 0.5)\n        {\n            continue;\n        }\n        float _5395 = (dot(fa_mesh_fs_params[29].xyz, _5278) + fa_mesh_fs_params[29].w) - _5377.x;\n        if ((_5395 > _5242) && (_5395 < _5247))\n        {\n            occ = max(occ, (1.0 - (_5270 * _5270)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5312, 0.5 - _5311), min(_5316, 1.0 - _5316))));\n        }\n    }\n    return 1.0 - (occ * _5228);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5498 = fa_baked_keep(param);\n    if (_5498 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5524 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7402 = _5524.color;\n    float _7403 = _5524.attenuation;\n    float _7404 = _5524.shadow;\n    bool _5527 = _5524.type == 0;\n    if (_5527 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5524.direction;\n        float _5538 = fa_shadow_factor(param_5, param_6);\n        _7404 = _5538;\n        _7402 *= _5538;\n    }\n    else\n    {\n        bool _5549 = _5524.type != 0;\n        bool _5555;\n        if (_5549)\n        {\n            _5555 = _7403 > 0.0;\n        }\n        else\n        {\n            _5555 = _5549;\n        }\n        if (_5555)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5524.direction;\n            float _5574 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _7404 = _5574;\n            _7402 *= _5574;\n        }\n    }\n    bool _5584 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5590;\n    if (_5584)\n    {\n        _5590 = _7403 > 0.0;\n    }\n    else\n    {\n        _5590 = _5584;\n    }\n    if (_5590)\n    {\n        float _5597;\n        if (_5527)\n        {\n            _5597 = 1000000000.0;\n        }\n        else\n        {\n            _5597 = _5524._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5524.direction;\n        float param_18 = _5597;\n        float _5615 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7404 *= _5615;\n        _7402 *= _5615;\n    }\n    float _5628 = _7403;\n    float _5629 = _5628 * _5498;\n    _7403 = _5629;\n    vec3 _5633 = _7402;\n    vec3 _5634 = _5633 * _5498;\n    _7402 = _5634;\n    return LightSample(_5524.direction, _5634, _5629, _7404, _5524._distance, _5524.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3116 = int(fa_shadows[25].x + 0.5);\n    float _3126 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3131 = _3116 > 0;\n    bool _3140;\n    if (_3131)\n    {\n        int param = _3116 - 1;\n        _3140 = _3126 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3140 = _3131;\n    }\n    if (_3140)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3146 = _3116 > 1;\n        bool _3153;\n        if (_3146)\n        {\n            _3153 = _3126 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3153 = _3146;\n        }\n        if (_3153)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3159 = _3116 > 2;\n        bool _3166;\n        if (_3159)\n        {\n            _3166 = _3126 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3166 = _3159;\n        }\n        if (_3166)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3172 = _3116 > 3;\n        bool _3179;\n        if (_3172)\n        {\n            _3179 = _3126 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3179 = _3172;\n        }\n        if (_3179)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7087 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7087 = -_7087;\n    }\n    vec3 _6710 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7087, fa_world_tangent, fa_uv, fa_vertex_color, _6710, gl_FrontFacing);\n    Surface _6718 = fa_standard_surface(param_1);\n    vec3 _7126 = _6718.albedo;\n    float _7127 = _6718.alpha;\n    vec3 _7128 = _6718.normal;\n    float _7129 = _6718.metallic;\n    float _7130 = _6718.roughness;\n    float _7131 = _6718.occlusion;\n    vec3 _7132 = _6718.emission;\n    float _7133 = _6718.clearcoat;\n    float _7134 = _6718.clearcoat_roughness;\n    vec3 _7135 = _6718.sheen_color;\n    float _7136 = _6718.sheen_roughness;\n    float _7137 = _6718.anisotropy;\n    float _7138 = _6718.anisotropy_rotation;\n    float _7139 = _6718.specular;\n    float _7140 = _6718.ior;\n    vec3 _7141 = _6718.specular_color;\n    float _7142 = _6718.transmission;\n    float _7143 = _6718.thickness;\n    vec3 _7144 = _6718.attenuation_color;\n    float _7145 = _6718.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7087, fa_world_tangent, fa_uv, fa_vertex_color, _6710, gl_FrontFacing);\n    Surface param_3 = _6718;\n    surface(param_2, param_3);\n    _7126 = param_3.albedo;\n    _7127 = param_3.alpha;\n    _7128 = param_3.normal;\n    _7129 = param_3.metallic;\n    _7130 = param_3.roughness;\n    _7131 = param_3.occlusion;\n    _7132 = param_3.emission;\n    _7133 = param_3.clearcoat;\n    _7134 = param_3.clearcoat_roughness;\n    _7135 = param_3.sheen_color;\n    _7136 = param_3.sheen_roughness;\n    _7137 = param_3.anisotropy;\n    _7138 = param_3.anisotropy_rotation;\n    _7139 = param_3.specular;\n    _7140 = param_3.ior;\n    _7141 = param_3.specular_color;\n    _7142 = param_3.transmission;\n    _7143 = param_3.thickness;\n    _7144 = param_3.attenuation_color;\n    _7145 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7087;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7126 = param_6;\n    _7128 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7126;\n    }\n    else\n    {\n        vec3 _6757 = _7128;\n        vec3 _6758 = normalize(_6757);\n        _7128 = _6758;\n        vec3 param_8 = _6758;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _7087, fa_world_tangent, fa_uv, fa_vertex_color, _6710, gl_FrontFacing);\n        Surface param_10 = Surface(_7126, _7127, _7128, _7129, _7130, _7131, _7132, _7133, _7134, _7135, _7136, _7137, _7138, _7139, _7140, _7141, _7142, _7143, _7144, _7145);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6777 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6777; ln++)\n        {\n            int param_12 = ln;\n            int _6790 = fa_cl_light(param_12);\n            int param_13 = _6790;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6790;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _7087;\n            LightSample _6806 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _7087, fa_world_tangent, fa_uv, fa_vertex_color, _6710, gl_FrontFacing);\n            Surface param_18 = Surface(_7126, _7127, _7128, _7129, _7130, _7131, _7132, _7133, _7134, _7135, _7136, _7137, _7138, _7139, _7140, _7141, _7142, _7143, _7144, _7145);\n            LightSample param_19 = _6806;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6821 = result;\n    vec3 _6822 = _6821 + _7132;\n    result = _6822;\n    vec3 param_20 = _6822;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6831 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6838;\n    if (!_6831)\n    {\n        _6838 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6838 = _6831;\n    }\n    if (_6838)\n    {\n        vec3 _6847 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6853 = dot(_6847, fa_mesh_fs_params[9].xyz);\n        bool _6857 = fa_mesh_fs_params[9].w > 0.5;\n        float _6858;\n        if (_6857)\n        {\n            _6858 = _6853;\n        }\n        else\n        {\n            _6858 = length(_6847);\n        }\n        float _6870 = _6858 - fa_mesh_fs_params[8].x;\n        if (_6870 > 0.0)\n        {\n            float _6879 = fa_mesh_fs_params[7].w * _6870;\n            float tau = _6879 * _6879;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6895;\n                if (_6857)\n                {\n                    _6895 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6853);\n                }\n                else\n                {\n                    _6895 = fa_mesh_fs_params[0].y;\n                }\n                float _6916 = mix(_6895, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6858, 0.0, 1.0));\n                float _6920 = fa_world_pos.y - _6916;\n                float _6925 = _6916 - fa_mesh_fs_params[8].z;\n                float _6930 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6933 = _6925 <= 0.0;\n                bool _6934 = !_6933;\n                bool _6940;\n                if (_6934)\n                {\n                    _6940 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6940 = _6933;\n                }\n                float _6941;\n                if (_6940)\n                {\n                    _6941 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6941 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6925, 80.0));\n                }\n                bool _6968;\n                if (_6934)\n                {\n                    _6968 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6968 = _6933;\n                }\n                float _6969;\n                if (_6968)\n                {\n                    _6969 = fa_mesh_fs_params[8].y * _6925;\n                }\n                else\n                {\n                    _6969 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6925, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6994 = _6930 <= 0.0;\n                bool _7001;\n                if (!_6994)\n                {\n                    _7001 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7001 = _6994;\n                }\n                float _7002;\n                if (_7001)\n                {\n                    _7002 = fa_mesh_fs_params[8].y * _6930;\n                }\n                else\n                {\n                    _7002 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6930, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7029;\n                if (abs(_6920) < 0.001000000047497451305389404296875)\n                {\n                    _7029 = _6941;\n                }\n                else\n                {\n                    _7029 = (_7002 - _6969) / _6920;\n                }\n                tau += (_6870 * max(_7029, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7127);\n}\n\n",
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
            "inst_name": "_505",
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
            "inst_name": "_2157",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4657[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1433 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1440;\n    if (!_1433)\n    {\n        _1440 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1440 = _1433;\n    }\n    bool _1448;\n    if (!_1440)\n    {\n        _1448 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1448 = _1440;\n    }\n    bool _1455;\n    if (!_1448)\n    {\n        _1455 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1455 = _1448;\n    }\n    bool _1462;\n    if (!_1455)\n    {\n        _1462 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1462 = _1455;\n    }\n    if (_1462)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1472 = vec4(world_pos, 1.0);\n    float _1478 = dot(fa_mesh_fs_params[16], _1472);\n    if (!(_1478 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1500 = vec2(dot(fa_mesh_fs_params[14], _1472), dot(fa_mesh_fs_params[15], _1472)) / vec2(_1478);\n    int _1504 = int(fa_mesh_fs_params[18].x);\n    int _1508 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1508) + clamp(int(floor(((_1500.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1508 - 1)) * _1504)) + clamp(int(floor(((_1500.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1504 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1584 = fa_cluster_texel(param);\n    return ivec2(int(_1584.x), int(_1584.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5472 = fa_cluster_lookup(param);\n    fa_cl_slot = _5472.x;\n    fa_cl_local = _5472.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5684 = fa_linear_to_srgb(param);\n        c = _5684;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5692 = fa_srgb_to_linear(param_1);\n            c = _5692;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _387;\n    if (i.front_facing)\n    {\n        _387 = i.world_normal;\n    }\n    else\n    {\n        _387 = -i.world_normal;\n    }\n    vec3 _411 = normalize(i.world_tangent.xyz - (_387 * dot(_387, i.world_tangent.xyz)));\n    vec3 _438 = normalize(((_411 * m.x) + ((cross(_387, _411) * i.world_tangent.w) * m.y)) + (_387 * m.z));\n    vec3 _441;\n    if (i.front_facing)\n    {\n        _441 = _438;\n    }\n    else\n    {\n        _441 = -_438;\n    }\n    return _441;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5724 = fa_tex_fix(param_2, param_3);\n    vec4 _7637 = base_t;\n    _7637.x = _5724.x;\n    _7637.y = _5724.y;\n    _7637.z = _5724.z;\n    base_t = _7637;\n    vec4 _5738 = (_7637 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7422 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5772 = fa_tex_fix(param_6, param_7);\n        vec3 _5775 = (_5772 * 2.0) - vec3(1.0);\n        vec2 _5780 = _5775.xy * fa_mesh_fs_params[6].x;\n        vec3 _7645 = _5775;\n        _7645.x = _5780.x;\n        _7645.y = _5780.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7645;\n        _7422 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5810 = fa_tex_fix(param_12, param_13);\n    vec4 _7648 = mrt;\n    _7648.x = _5810.x;\n    _7648.y = _5810.y;\n    _7648.z = _5810.z;\n    mrt = _7648;\n    vec4 _5840 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5840.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5851 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5883 = fa_tex_fix(param_20, param_21);\n    float _7427 = fa_mesh_fs_params[20].x;\n    float _7428 = fa_mesh_fs_params[20].y;\n    float _7431 = fa_mesh_fs_params[20].z;\n    float _7430 = fa_mesh_fs_params[21].w;\n    float _7433 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7427 *= _5851.y;\n            _7428 *= _5851.z;\n            _7430 *= _5840.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7431 *= mrt.x;\n            _7433 *= mrt.w;\n        }\n    }\n    return Surface(_5738.xyz, _5738.w, _7422, clamp(fa_mesh_fs_params[5].x * _5810.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5810.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5851.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5883), _7427, _7428, fa_mesh_fs_params[21].xyz, _7430, _7431, fa_mesh_fs_params[20].w, _7433, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1664 = rect.zw - rect.xy;\n    vec2 _1668 = _1664 * atlas;\n    vec2 _1672 = ddx * _1668;\n    vec2 _1676 = ddy * _1668;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1664), clamp(0.5 * log2(max(max(dot(_1672, _1672), dot(_1676, _1676)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1709 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1716;\n    if (!_1709)\n    {\n        _1716 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1716 = _1709;\n    }\n    if (_1716)\n    {\n        return;\n    }\n    vec3 _1722 = dFdx(world_pos);\n    vec3 _1725 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1729 = fa_cluster_texel(param);\n    int _1733 = int(_1729.w);\n    if (_1733 < 1)\n    {\n        return;\n    }\n    int _1743 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1743;\n    vec4 _1747 = fa_light_texel(param_1);\n    vec2 _1750 = _1747.yz;\n    int _1754 = int(_1747.w);\n    int param_2 = _1743 + 1;\n    vec4 _1759 = fa_light_texel(param_2);\n    float _1760 = _1759.x;\n    int _1766 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1770 = int(_1729.z);\n    vec3 _2035;\n    for (int k = 0; k < _1733; k++)\n    {\n        int _1783 = _1770 + k;\n        int param_3 = _1754 + (_1783 >> 2);\n        int _1800 = (_1743 + 2) + (int(fa_light_texel(param_3)[_1783 & 3]) * 7);\n        int param_4 = _1800 + 6;\n        vec4 _1805 = fa_light_texel(param_4);\n        if (((int(_1805.w + 0.5) >> _1766) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1800;\n        vec4 _1820 = fa_light_texel(param_5);\n        int param_6 = _1800 + 1;\n        vec4 _1825 = fa_light_texel(param_6);\n        int param_7 = _1800 + 2;\n        vec4 _1830 = fa_light_texel(param_7);\n        vec3 _1833 = _1820.xyz;\n        float _1838 = dot(_1833, world_pos) + _1820.w;\n        vec3 _1840 = _1825.xyz;\n        float _1845 = dot(_1840, world_pos) + _1825.w;\n        vec3 _1847 = _1830.xyz;\n        float _1852 = dot(_1847, world_pos) + _1830.w;\n        bool _1857 = abs(_1838) > 0.5;\n        bool _1865;\n        if (!_1857)\n        {\n            _1865 = abs(_1845) > 0.5;\n        }\n        else\n        {\n            _1865 = _1857;\n        }\n        bool _1873;\n        if (!_1865)\n        {\n            _1873 = abs(_1852) > 0.5;\n        }\n        else\n        {\n            _1873 = _1865;\n        }\n        if (_1873)\n        {\n            continue;\n        }\n        float _1888 = clamp(dot(geo_normal, normalize(_1847)) * _1805.z, 0.0, 1.0);\n        if (_1888 <= 0.0)\n        {\n            continue;\n        }\n        float _1908 = (clamp((0.5 - abs(_1852)) * 10.0, 0.0, 1.0) * _1888) * _1805.x;\n        vec2 _1916 = vec2(_1838 + 0.5, 0.5 - _1845);\n        vec2 _1926 = vec2(dot(_1833, _1722), dot(_1840, _1722));\n        vec2 _1936 = vec2(dot(_1833, _1725), dot(_1840, _1725));\n        int param_8 = _1800 + 5;\n        vec4 _1941 = fa_light_texel(param_8);\n        int param_9 = _1800 + 3;\n        vec4 _1946 = fa_light_texel(param_9);\n        int param_10 = _1800 + 4;\n        vec4 _1951 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1941.xyz;\n        bool _1961 = _1946.z > _1946.x;\n        if (_1961)\n        {\n            vec4 param_11 = _1946;\n            vec2 param_12 = _1916;\n            vec2 param_13 = _1750;\n            vec2 param_14 = _1926;\n            vec2 param_15 = _1936;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1760 > 0.5) && (_1760 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1987 = fa_dc_to_linear(param_16);\n                vec4 _7510 = tx;\n                _7510.x = _1987.x;\n                _7510.y = _1987.y;\n                _7510.z = _1987.z;\n                tx = _7510;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1908 * tex_a) * _1941.w, 0.0, 1.0)));\n        if (_1951.z > _1951.x)\n        {\n            vec4 param_17 = _1951;\n            vec2 param_18 = _1916;\n            vec2 param_19 = _1750;\n            vec2 param_20 = _1926;\n            vec2 param_21 = _1936;\n            vec4 _2031 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1760 > 1.5)\n            {\n                vec3 param_22 = _2031.xyz;\n                vec3 _2041 = fa_dc_to_srgb(param_22);\n                _2035 = _2041;\n            }\n            else\n            {\n                _2035 = _2031.xyz;\n            }\n            vec3 _2050 = (_2035 * 2.0) - vec3(1.0);\n            vec2 _2055 = _2050.xy * _1805.y;\n            vec3 _2077 = (normalize(_1833) * _2055.x) + (normalize(_1840) * _2055.y);\n            vec3 _2080 = normalize(normal);\n            normal = normalize(mix(_2080, normalize((_2080 * max(_2050.z, 0.0500000007450580596923828125)) + (_2077 - (_2080 * dot(_2080, _2077)))), vec3(clamp(_1908 * (_1961 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3752 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3752;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4363 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4368 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4363 > 0.0005000000237487256526947021484375)\n    {\n        if (_4368)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4363;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4363;\n        }\n    }\n    bool _4419 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4419)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4450 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4450)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4368 || _4419) || _4450)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3772 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3775 = _3772.x;\n    float _3777 = _3772.z;\n    vec2 e = vec2(_3775, _3777);\n    if (_3772.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3777)) * ((_3775 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3775)) * ((_3777 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5995 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _6000 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _6005 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _6010 = fa_light_texel(param_3);\n    bool _6013 = _6010.z < 0.5;\n    bool _6021;\n    if (!_6013)\n    {\n        _6021 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _6021 = _6013;\n    }\n    if (_6021)\n    {\n        return vec3(0.0);\n    }\n    float _6028 = max(_5995.w, 9.9999997473787516355514526367188e-05);\n    vec3 _6031 = _6000.xyz;\n    vec3 _6035 = _5995.xyz;\n    vec3 _6039 = (fa_world_pos - _6035) / vec3(_6028);\n    vec3 _6048 = min(_6039 + vec3(0.5), (_6031 - vec3(0.5)) - _6039);\n    float _6057 = min(_6048.x, min(_6048.y, _6048.z));\n    if (!(_6057 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6072 = _6031 - vec3(1.0);\n    vec3 _6073 = clamp(_6039, vec3(0.0), _6072);\n    vec3 _6081 = min(floor(_6073), max(_6031 - vec3(2.0), vec3(0.0)));\n    vec3 _6085 = _6073 - _6081;\n    vec3 _6096 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _6028));\n    int _6101 = int(_6005.y + 0.5);\n    float _6106 = 0.3257350027561187744140625 * n.y;\n    float _6110 = 0.3257350027561187744140625 * n.z;\n    float _6114 = 0.3257350027561187744140625 * n.x;\n    float _6121 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _6128 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _6137 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _6144 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _6157 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _6164 = 8 + int(_6010.w);\n    float _6191;\n    float _6204;\n    float _6218;\n    for (int k = 0; k < _6164; k++)\n    {\n        float _6177 = float(k & 1);\n        float _6181 = float((k >> 1) & 1);\n        float _6185 = float((k >> 2) & 1);\n        if (_6177 > 0.5)\n        {\n            _6191 = _6085.x;\n        }\n        else\n        {\n            _6191 = 1.0 - _6085.x;\n        }\n        if (_6181 > 0.5)\n        {\n            _6204 = _6085.y;\n        }\n        else\n        {\n            _6204 = 1.0 - _6085.y;\n        }\n        if (_6185 > 0.5)\n        {\n            _6218 = _6085.z;\n        }\n        else\n        {\n            _6218 = 1.0 - _6085.z;\n        }\n        float _6228 = (_6191 * _6204) * _6218;\n        if (!(_6228 > 0.0))\n        {\n            continue;\n        }\n        vec3 _6241 = min(_6081 + vec3(_6177, _6181, _6185), _6072);\n        int _6261 = int(((_6005.x + _6241.x) + (_6000.x * (_6241.y + (_6000.y * _6241.z)))) + 0.5);\n        vec2 _6276 = vec2(float(_6261 % _6101) * 10.0, 1024.0 + (float(_6261 / _6101) * 11.0));\n        vec2 param_4 = _6276 + vec2(9.5, 10.5);\n        vec4 _6284 = fa_gi_fetch(param_4);\n        bool _6287 = _6284.y < 0.5;\n        bool _6296;\n        if (!_6287)\n        {\n            _6296 = _6284.x > _6010.y;\n        }\n        else\n        {\n            _6296 = _6287;\n        }\n        if (_6296)\n        {\n            continue;\n        }\n        vec3 _6308 = _6096 - (_6035 + (_6241 * _6028));\n        float _6311 = length(_6308);\n        vec3 _6317 = _6308 / vec3(max(_6311, 9.9999997473787516355514526367188e-05));\n        float _6327 = max(9.9999997473787516355514526367188e-05, (dot(-_6317, n) + 1.0) * 0.5);\n        float w = _6228 * (_6327 * _6327);\n        vec3 param_5 = _6317;\n        vec2 param_6 = (_6276 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _6346 = fa_gi_fetch(param_6);\n        float _6353 = _6311 / max(_6005.z, 9.9999997473787516355514526367188e-05);\n        float _6356 = _6346.x;\n        if (_6353 > _6356)\n        {\n            float _6369 = max(_6346.y - (_6356 * _6356), 0.0);\n            float _6374 = _6353 - _6356;\n            float _6383 = _6369 / max(_6369 + (_6374 * _6374), 9.9999999600419720025001879548654e-13);\n            w *= ((_6383 * _6383) * _6383);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _6276 + vec2(0.5, 10.5);\n        vec2 param_8 = _6276 + vec2(1.5, 10.5);\n        vec2 param_9 = _6276 + vec2(2.5, 10.5);\n        vec2 param_10 = _6276 + vec2(3.5, 10.5);\n        vec2 param_11 = _6276 + vec2(4.5, 10.5);\n        vec2 param_12 = _6276 + vec2(5.5, 10.5);\n        vec2 param_13 = _6276 + vec2(6.5, 10.5);\n        vec2 param_14 = _6276 + vec2(7.5, 10.5);\n        vec2 param_15 = _6276 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _6106)) + (fa_gi_fetch(param_9).xyz * _6110)) + (fa_gi_fetch(param_10).xyz * _6114)) + (fa_gi_fetch(param_11).xyz * _6121)) + (fa_gi_fetch(param_12).xyz * _6128)) + (fa_gi_fetch(param_13).xyz * _6137)) + (fa_gi_fetch(param_14).xyz * _6144)) + (fa_gi_fetch(param_15).xyz * _6157)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_6057 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6509;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6509 = _6010.x;\n    }\n    else\n    {\n        _6509 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_6005.w * _6509);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6533 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6538 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6543 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6543) && (k < 8); k++)\n    {\n        int param = _6538 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6533;\n        vec3 _6568 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6573 = param_3 * left;\n        acc += (_6568 * _6573);\n        left -= _6573;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6602 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6602;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4582 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4590 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4593 = int(_4582);\n    int _4596 = int(_4590);\n    float _4606 = _4590 - float(_4596);\n    int _4661 = (_4593 * 9) + _4596;\n    int _4681 = ((_4593 + 1) * 9) + _4596;\n    return mix(mix(_4657[_4661], _4657[_4661 + 1], _4606), mix(_4657[_4681], _4657[_4681 + 1], _4606), _4582 - float(_4593));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7281 = false;\n    float _7282 = 1.0;\n    float _7283 = 1.0;\n    float _7284 = 1.0;\n    float _7285 = 0.0;\n    float _7286 = 0.0;\n    float _7287 = 0.0;\n    float _7288 = 0.0;\n    float _7290 = 1.0;\n    bool _7291 = false;\n    vec3 _7292 = vec3(0.0);\n    float _7293 = 1.0;\n    float _7294 = 1.0;\n    float _7295 = 1.0;\n    float _7296 = 0.0;\n    float _7297 = 0.0;\n    vec3 _7298 = vec3(1.0, 0.0, 0.0);\n    vec3 _7299 = vec3(0.0, 0.0, 1.0);\n    float _7300 = 1.0;\n    float _7301 = 1.0;\n    float _4732 = clamp(s.specular, 0.0, 1.0);\n    float _4736 = clamp(s.ior, 1.0, 3.0);\n    bool _4741 = (_4732 != 1.0) || (_4736 != 1.5);\n    bool _4750;\n    if (!_4741)\n    {\n        _4750 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4750 = _4741;\n    }\n    if (_4750)\n    {\n        float _4758 = (_4736 - 1.0) / (_4736 + 1.0);\n        f0 = mix(min(vec3(_4758 * _4758) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4732, s.albedo, vec3(metallic));\n        _7282 = mix(_4732, 1.0, metallic);\n        _7281 = true;\n    }\n    float _4785 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4785 > 0.0)\n    {\n        float _4793 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7285 = _4785;\n        _7286 = _4793;\n        float _4800 = _4793 * _4793;\n        _7287 = _4800;\n        _7288 = _4800 * _4800;\n        float _4812 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7290 = _4812;\n        _7283 = 1.0 - (_4785 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4812, 0.0, 1.0), 5.0))));\n        _7281 = true;\n    }\n    vec3 _4831 = max(s.sheen_color, vec3(0.0));\n    float _4840 = max(_4831.x, max(_4831.y, _4831.z));\n    if (_4840 > 0.0)\n    {\n        float _4848 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7291 = true;\n        _7292 = _4831;\n        _7293 = _4848;\n        _7294 = _4848 * _4848;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4848;\n        float _4865 = fa_sheen_albedo(param, param_1);\n        _7296 = _4865;\n        _7295 = 1.0 - min(_4840 * _4865, 1.0);\n        _7281 = true;\n    }\n    _7284 = _7283 * _7295;\n    float _4884 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4884 != 0.0)\n    {\n        vec3 _4899 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4899;\n        if (dot(_4899, _4899) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4911 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4911.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4911.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4911.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4915 = t;\n        vec3 _4916 = normalize(_4915);\n        t = _4916;\n        vec3 _4941 = normalize((_4916 * cos(s.anisotropy_rotation)) + ((cross(n, _4916) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7298 = _4941;\n        _7299 = cross(n, _4941);\n        float _4951 = roughness * roughness;\n        float _4957 = mix(_4951, 1.0, _4884 * _4884);\n        bool _4959 = _4884 > 0.0;\n        _7300 = _4959 ? _4957 : _4951;\n        _7301 = _4959 ? _4951 : _4957;\n        _7297 = _4884;\n        _7281 = true;\n    }\n    return FaLayers(_7281, _7282, _7283, _7284, _7285, _7286, _7287, _7288, i.world_normal, _7290, _7291, _7292, _7293, _7294, _7295, _7296, _7297, _7298, _7299, _7300, _7301);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4514 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4517 = _4514.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4517 * _4517, exp2((-9.27999973297119140625) * ndv)) * _4517) + _4514.y)) + _4514.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3824;\n    if (lv == 0)\n    {\n        _3824 = 0.0;\n    }\n    else\n    {\n        _3824 = res + 2.0;\n    }\n    float _3834;\n    if (lv == 0)\n    {\n        _3834 = 0.0;\n    }\n    else\n    {\n        _3834 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3824, _3834)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3880;\n    if (res > 64.5)\n    {\n        _3880 = 5.0;\n    }\n    else\n    {\n        _3880 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3895 = clamp(rough, 0.0, 1.0) * (_3880 - 1.0);\n    int _3902 = int(min(floor(_3895), _3880 - 2.0));\n    float _3907 = _3895 - float(_3902);\n    vec3 param = d;\n    vec2 _3911 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3902;\n    vec2 param_4 = _3911;\n    vec3 _3921 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3907 < 0.00200000009499490261077880859375)\n    {\n        return _3921;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3902 + 1;\n    vec2 param_8 = _3911;\n    return mix(_3921, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3907));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3992 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3999 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4006 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4012 = dot(bx.xyz, d);\n    float _4016 = dot(by.xyz, d);\n    float _4020 = dot(bz.xyz, d);\n    float _4026;\n    if (_4012 > 9.9999999747524270787835121154785e-07)\n    {\n        _4026 = (1.0 - _3992) / _4012;\n    }\n    else\n    {\n        float _4040;\n        if (_4012 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4040 = ((-1.0) - _3992) / _4012;\n        }\n        else\n        {\n            _4040 = 1000000015047466219876688855040.0;\n        }\n        _4026 = _4040;\n    }\n    float tx = _4026;\n    float _4057;\n    if (_4016 > 9.9999999747524270787835121154785e-07)\n    {\n        _4057 = (1.0 - _3999) / _4016;\n    }\n    else\n    {\n        float _4070;\n        if (_4016 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4070 = ((-1.0) - _3999) / _4016;\n        }\n        else\n        {\n            _4070 = 1000000015047466219876688855040.0;\n        }\n        _4057 = _4070;\n    }\n    float ty = _4057;\n    float _4086;\n    if (_4020 > 9.9999999747524270787835121154785e-07)\n    {\n        _4086 = (1.0 - _4006) / _4020;\n    }\n    else\n    {\n        float _4099;\n        if (_4020 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4099 = ((-1.0) - _4006) / _4020;\n        }\n        else\n        {\n            _4099 = 1000000015047466219876688855040.0;\n        }\n        _4086 = _4099;\n    }\n    float _4111 = tx;\n    float _4114 = (_4111 > 0.0) ? _4111 : 1000000015047466219876688855040.0;\n    tx = _4114;\n    float _4115 = ty;\n    float _4118 = (_4115 > 0.0) ? _4115 : 1000000015047466219876688855040.0;\n    ty = _4118;\n    float _4128 = min(_4114, min(_4118, (_4086 > 0.0) ? _4086 : 1000000015047466219876688855040.0));\n    if (_4128 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4144 = (fa_world_pos + (d * _4128)) - posw.xyz;\n    vec3 _4149;\n    if (dot(_4144, _4144) > 1.0000000133514319600180897396058e-10)\n    {\n        _4149 = normalize(_4144);\n    }\n    else\n    {\n        _4149 = d;\n    }\n    return _4149;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4195 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4195 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4223 = rough * rough;\n            float _4254 = 0.60000002384185791015625 * _4223;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4223)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4254, 0.0500000007450580596923828125 + _4254, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4223 * 0.60000002384185791015625));\n        }\n        outc = base * _4195;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4313 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4313 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4345 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4345 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4992;\n        if (L.aniso >= 0.0)\n        {\n            _4992 = L.b;\n        }\n        else\n        {\n            _4992 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4992, v), _4992), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5028 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5028.x) + (vec3(L.f90) * _5028.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5086 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5086.x) + _5086.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4556 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4556.x) + vec3(_4556.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _5115 = clamp(s.metallic, 0.0, 1.0);\n    float _5119 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _5126 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_5115));\n    vec3 f0 = _5126;\n    vec3 _5130 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _5130;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _5115;\n    float param_5 = _5119;\n    vec3 param_6 = _5126;\n    FaLayers _5147 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_5147.on)\n    {\n        FaLayers param_7 = _5147;\n        vec3 param_8 = _5130;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _5119;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _5130;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _5119;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5442;\n    if (fa_lm.z > 0.5)\n    {\n        _5442 = 0.0;\n    }\n    else\n    {\n        _5442 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5453 = _5442 < 1.0;\n    bool _5459;\n    if (_5453)\n    {\n        int param = li;\n        _5459 = fa_light_baked(param);\n    }\n    else\n    {\n        _5459 = _5453;\n    }\n    return _5459 ? _5442 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _683 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _696 = (c - (ru * hx)) - p;\n        vec3 _702 = ru * (2.0 * hx);\n        float _708 = max(dot(_702, _702), 9.9999999392252902907785028219223e-09);\n        float _712 = dot(_696, _702);\n        float t = clamp((-_712) / _708, 0.0, 1.0);\n        if (_683)\n        {\n            float _727 = dot(r, _702);\n            float _733 = _708 - (_727 * _727);\n            if (abs(_733) > (9.9999997473787516355514526367188e-06 * _708))\n            {\n                t = clamp(((dot(r, _696) * _727) - _712) / _733, 0.0, 1.0);\n            }\n        }\n        return (p + _696) + (_702 * t);\n    }\n    vec3 q = p;\n    float _765 = dot(r, axis);\n    bool _773;\n    if (_683)\n    {\n        _773 = abs(_765) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _773 = _683;\n    }\n    if (_773)\n    {\n        float _783 = dot(c - p, axis) / _765;\n        if (_783 > 0.0)\n        {\n            q = p + (r * _783);\n        }\n    }\n    vec3 _796 = q - c;\n    vec2 xy = vec2(dot(_796, ru), dot(_796, uu));\n    if (shape > 0.5)\n    {\n        float _811 = length(xy);\n        if (_811 > hx)\n        {\n            xy *= (hx / _811);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _603 = dot(d, right);\n    float _607 = dot(d, up);\n    float _618;\n    if (((_603 * _603) + (_607 * _607)) > 1.0000000133514319600180897396058e-10)\n    {\n        _618 = atan(_607, _603) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _618 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_618 - floor(_618)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _453 = abs(d);\n    float _455 = _453.x;\n    float _457 = _453.y;\n    bool _458 = _455 >= _457;\n    bool _466;\n    if (_458)\n    {\n        _466 = _455 >= _453.z;\n    }\n    else\n    {\n        _466 = _458;\n    }\n    int _467;\n    if (_466)\n    {\n        _467 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _482;\n        if (_457 >= _453.z)\n        {\n            _482 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _482 = (d.z > 0.0) ? 4 : 5;\n        }\n        _467 = _482;\n    }\n    return _467;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _849 = fa_light_base(param);\n    bool _853 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _849;\n    vec4 _857 = fa_light_texel(param_1);\n    int param_2 = _849 + 1;\n    vec4 _862 = fa_light_texel(param_2);\n    float _865 = _862.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _877 = _853 && (_865 > 2.5);\n    fa_light_is_area = _877;\n    bool _879 = _865 < 0.5;\n    vec3 l;\n    if (_879)\n    {\n        l = normalize(_857.xyz);\n        if (_853)\n        {\n            int param_3 = _849 + 6;\n            vec4 _893 = fa_light_texel(param_3);\n            if (_893.z > 0.5)\n            {\n                int param_4 = _849 + 4;\n                vec4 _903 = fa_light_texel(param_4);\n                int param_5 = _849 + 5;\n                vec4 _908 = fa_light_texel(param_5);\n                vec2 param_6 = _893.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _903.xyz) * _903.w, (-dot(world_pos, _908.xyz)) * _908.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _938 = _857.xyz;\n        vec3 _940 = _938 - world_pos;\n        vec3 to_light = _940;\n        float _943 = length(_940);\n        float reach = _943;\n        bool front = true;\n        if (_877)\n        {\n            int param_8 = _849 + 7;\n            reach = max(_943 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _849 + 4;\n            vec4 _967 = fa_light_texel(param_9);\n            int param_10 = _849 + 5;\n            vec4 _972 = fa_light_texel(param_10);\n            int param_11 = _849 + 6;\n            vec4 _977 = fa_light_texel(param_11);\n            float _978 = _977.w;\n            int param_12 = _849 + 2;\n            vec3 _985 = normalize(fa_light_texel(param_12).xyz);\n            bool _987 = _978 > 1.5;\n            bool _995;\n            if (!_987)\n            {\n                _995 = dot(_985, to_light) < 0.0;\n            }\n            else\n            {\n                _995 = _987;\n            }\n            front = _995;\n            vec3 r = vec3(0.0);\n            vec3 _1004 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1008 = dot(n, n) > 0.5;\n            bool _1016;\n            if (_1008)\n            {\n                _1016 = dot(_1004, _1004) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1016 = _1008;\n            }\n            if (_1016)\n            {\n                r = reflect(-normalize(_1004), normalize(n));\n            }\n            vec3 param_13 = _938;\n            vec3 param_14 = _985;\n            vec3 param_15 = _967.xyz;\n            vec3 param_16 = _972.xyz;\n            float param_17 = _967.w;\n            float param_18 = _972.w;\n            float param_19 = _978;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1052 = length(to_light);\n        dist = _1052;\n        l = to_light / vec3(max(_1052, 9.9999997473787516355514526367188e-05));\n        float _1066 = reach / max(_857.w, 0.001000000047497451305389404296875);\n        float _1072 = clamp(1.0 - (_1066 * _1066), 0.0, 1.0);\n        float _1074;\n        if (front)\n        {\n            _1074 = _1072 * _1072;\n        }\n        else\n        {\n            _1074 = 0.0;\n        }\n        atten = _1074;\n        bool _1085 = _865 < 2.5;\n        if ((_865 > 1.5) && _1085)\n        {\n            int param_22 = _849 + 2;\n            vec4 _1093 = fa_light_texel(param_22);\n            float _1103 = _1093.w;\n            int param_23 = _849 + 3;\n            vec4 _1108 = fa_light_texel(param_23);\n            float _1109 = _1108.x;\n            float cos_inner = _1109;\n            if (_1109 > 1.5)\n            {\n                cos_inner = mix(_1103, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1103, cos_inner, dot(-l, normalize(_1093.xyz)));\n        }\n        if (_853 && (_865 < 1.5))\n        {\n            int param_24 = _849 + 6;\n            vec4 _1133 = fa_light_texel(param_24);\n            if (_1133.z > 0.5)\n            {\n                vec3 _1141 = -to_light;\n                int param_25 = _849 + 4;\n                int param_26 = _849 + 5;\n                vec3 _1155 = fa_light_texel(param_25).xyz;\n                vec3 _1159 = fa_light_texel(param_26).xyz;\n                vec3 _1168 = vec3(dot(_1141, _1155), dot(_1141, _1159), dot(_1141, cross(_1155, _1159)));\n                vec3 param_27 = _1168;\n                int _1172 = fa_cube_face(param_27);\n                int param_28 = _1172;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1199 = vec2(dot(_1168, cross(param_29, param_30)), dot(_1168, param_30)) / vec2(max(dot(_1168, param_29), 9.9999997473787516355514526367188e-05));\n                int _1203 = _1172 / 3;\n                vec2 param_31 = _1133.xy + (vec2(float(_1172 - (_1203 * 3)), float(_1203)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1199.x), 0.5 - (0.5 * _1199.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _849 + 7;\n            vec4 _1233 = fa_light_texel(param_33);\n            if (_1233.z > 0.5)\n            {\n                int param_34 = _849 + 2;\n                int param_35 = _849 + 4;\n                int param_36 = _849 + 5;\n                vec2 param_37 = _1233.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_853 && _1085)\n            {\n                int param_42 = _849 + 6;\n                vec4 _1280 = fa_light_texel(param_42);\n                int param_43 = _849 + 7;\n                vec4 _1285 = fa_light_texel(param_43);\n                bool _1288 = _1280.z > 0.5;\n                bool _1295;\n                if (!_1288)\n                {\n                    _1295 = _1285.z > 0.5;\n                }\n                else\n                {\n                    _1295 = _1288;\n                }\n                if (_1295)\n                {\n                    int param_44 = _849 + 2;\n                    vec4 _1302 = fa_light_texel(param_44);\n                    vec3 _1306 = normalize(_1302.xyz);\n                    int param_45 = _849 + 4;\n                    vec4 _1311 = fa_light_texel(param_45);\n                    int param_46 = _849 + 5;\n                    vec4 _1316 = fa_light_texel(param_46);\n                    if (_1288)\n                    {\n                        vec3 _1324 = -to_light;\n                        float _1331 = _1302.w;\n                        float _1347 = 0.5 / max(dot(_1324, _1306) * (sqrt(max(1.0 - (_1331 * _1331), 0.0)) / max(_1331, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1280.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1324, _1311.xyz) * _1347), 0.5 - (dot(_1324, _1316.xyz) * _1347));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1285.z > 0.5)\n                    {\n                        vec2 param_49 = _1285.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1306;\n                        vec3 param_52 = _1311.xyz;\n                        vec3 param_53 = _1316.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7269 = _862.xyz * atten;\n    if (_853)\n    {\n        _7269 *= fa_light_tint;\n    }\n    int _1415;\n    if (_879)\n    {\n        _1415 = 0;\n    }\n    else\n    {\n        _1415 = ((_865 > 1.5) && (_865 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7269, atten, 1.0, dist, _1415);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2204 = fa_shadow_depth(param, param_1);\n    float _2208;\n    if (conv.x < 0.5)\n    {\n        _2208 = _2204;\n    }\n    else\n    {\n        _2208 = (conv.y * conv.z) / (conv.z - (_2204 * (conv.z - conv.y)));\n    }\n    return _2208;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2254 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2260 = vec2(cos(_2254), sin(_2254));\n    vec2 dir = _2260;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2269;\n        if (k < 0.0)\n        {\n            _2269 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2269 = k;\n        }\n        float _2288 = clamp((_2269 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2307 = sqrt((float(i) + 0.5) * 0.0625) * _2288;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2307));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2321 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2321 < (zr - (_2307 * plane)))\n            {\n                sum += _2321;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2349 = sum / cnt;\n        float _2359;\n        if (k < 0.0)\n        {\n            _2359 = (-k) / max(_2349, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2359 = k;\n        }\n        radius = clamp(((max(zr - _2349, 0.0) * unit) * _2359) / texel_m, 1.5, 16.0);\n        dir = _2260;\n    }\n    float lit = 0.0;\n    int _2385 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2385; i_1++)\n    {\n        float _2404 = sqrt((float(i_1) + 0.5) / float(_2385)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2404));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2404 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2385);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2609 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2616;\n    if (!_2609)\n    {\n        _2616 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2616 = _2609;\n    }\n    if (_2616)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2629 = fa_light_texel(param);\n    float _2630 = _2629.x;\n    if (_2630 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2639 = int(_2630 + 0.5);\n    int param_1 = _2639;\n    vec4 _2643 = fa_light_texel(param_1);\n    int param_2 = _2639 + 1;\n    vec4 _2648 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2651 = _2643.y;\n    if (_2651 > 0.0)\n    {\n        float _2668 = 1.0 - smoothstep(0.75 * _2651, _2651, length(world - fa_shadows[27].xyz));\n        fade = _2668;\n        if (_2668 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2643.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2692 = (_2639 + 2) + (face * 6);\n    int param_4 = _2692;\n    int param_5 = _2692 + 1;\n    int param_6 = _2692 + 3;\n    vec4 _2706 = fa_light_texel(param_6);\n    int param_7 = _2692 + 4;\n    vec4 _2711 = fa_light_texel(param_7);\n    int param_8 = _2692 + 5;\n    vec4 _2716 = fa_light_texel(param_8);\n    float _2728 = _2716.x * max(dot(_2706, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2733 = clamp(dot(n, l), 0.0, 1.0);\n    float _2756 = clamp(dot(n, _2706.xyz), -1.0, 1.0);\n    float _2775 = min(sqrt(1.0 - (_2756 * _2756)) / max(abs(dot(n, world - lpos)) / max(dot(_2706, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2778 = _2648.y;\n    float _2780;\n    if (_2778 > 0.0)\n    {\n        _2780 = _2778;\n    }\n    else\n    {\n        _2780 = 1.5 * _2728;\n    }\n    vec4 _2800 = vec4(world + (n * (_2780 * sqrt(1.0 - (_2733 * _2733)))), 1.0);\n    float _2804 = dot(_2706, _2800);\n    float _2807 = _2716.y;\n    if (_2804 < _2807)\n    {\n        return 1.0;\n    }\n    vec2 _2822 = vec2(dot(fa_light_texel(param_4), _2800), dot(fa_light_texel(param_5), _2800)) / vec2(_2804);\n    float _2824 = _2822.x;\n    bool _2827 = _2824 < _2711.x;\n    bool _2836;\n    if (!_2827)\n    {\n        _2836 = _2824 > _2711.z;\n    }\n    else\n    {\n        _2836 = _2827;\n    }\n    bool _2845;\n    if (!_2836)\n    {\n        _2845 = _2822.y < _2711.y;\n    }\n    else\n    {\n        _2845 = _2836;\n    }\n    bool _2854;\n    if (!_2845)\n    {\n        _2854 = _2822.y > _2711.w;\n    }\n    else\n    {\n        _2854 = _2845;\n    }\n    if (_2854)\n    {\n        return 1.0;\n    }\n    float _2860 = _2648.x;\n    float _2862;\n    if (_2860 > 0.0)\n    {\n        _2862 = _2860;\n    }\n    else\n    {\n        _2862 = 1.5 * _2728;\n    }\n    vec2 param_9 = _2822;\n    vec4 param_10 = _2711;\n    float param_11 = _2804 - (_2862 * (1.0 + (0.5 * _2775)));\n    float param_12 = _2728;\n    float param_13 = 1.0;\n    float param_14 = _2716.z * 0.25;\n    float param_15 = (_2728 * min(_2775, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2807, _2716.z);\n    int param_17 = int(_2643.z + 0.5);\n    float param_18 = _2643.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3374 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3380;\n    if (_3374)\n    {\n        _3380 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3380 = _3374;\n    }\n    bool _3386;\n    if (_3380)\n    {\n        _3386 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3386 = _3380;\n    }\n    if (_3386)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3398 = fa_light_texel(param);\n        float _3399 = _3398.z;\n        if (_3399 > 0.5)\n        {\n            float _3412 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3415 = fwidth(_3412);\n            float _3419 = min(1.5 * _3415, 0.100000001490116119384765625 * _3412);\n            vec4 _3425 = vec4(world, 1.0);\n            float _3430 = dot(fa_mesh_fs_params[28], _3425);\n            if (_3430 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3447 = vec2(dot(fa_mesh_fs_params[26], _3425), dot(fa_mesh_fs_params[27], _3425)) / vec2(_3430);\n                float _3452 = (_3447.x * 0.5) + 0.5;\n                float _3456;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3456 = (_3447.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3456 = 0.5 - (_3447.y * 0.5);\n                }\n                bool _3472 = _3452 >= 0.0;\n                bool _3478;\n                if (_3472)\n                {\n                    _3478 = _3452 < 1.0;\n                }\n                else\n                {\n                    _3478 = _3472;\n                }\n                bool _3484;\n                if (_3478)\n                {\n                    _3484 = _3456 >= 0.0;\n                }\n                else\n                {\n                    _3484 = _3478;\n                }\n                bool _3490;\n                if (_3484)\n                {\n                    _3490 = _3456 < 1.0;\n                }\n                else\n                {\n                    _3490 = _3484;\n                }\n                if (_3490)\n                {\n                    ivec2 _3507 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3508 = clamp(ivec2(vec2(_3452, _3456) * fa_mesh_fs_params[24].zw), ivec2(0), _3507);\n                    ivec2 _3520;\n                    ivec2 _3526;\n                    ivec2 _3533;\n                    float _3584;\n                    float _3605;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3520 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3526 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3533 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3544 = bvec2(k == 3);\n                                    _3533 = ivec2(_3544.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3544.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3526 = _3533;\n                            }\n                            _3520 = _3526;\n                        }\n                        vec4 _3561 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3508 + _3520, ivec2(0), _3507), 0);\n                        bool _3564 = _3561.w > 0.5;\n                        bool _3578;\n                        if (_3564)\n                        {\n                            _3578 = abs(_3412 - _3561.x) <= (((0.00200000009499490261077880859375 * _3412) + 0.00999999977648258209228515625) + _3419);\n                        }\n                        else\n                        {\n                            _3578 = _3564;\n                        }\n                        if (_3578)\n                        {\n                            if (_3399 < 1.5)\n                            {\n                                _3584 = 1.0;\n                            }\n                            else\n                            {\n                                _3584 = (_3399 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3601 = mod(floor(_3561.z / _3584), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3605 = min(_3601, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3605 = _3601;\n                            }\n                            return _3605;\n                        }\n                    }\n                }\n            }\n            float _3630;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3630 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3630 = 1.0;\n            }\n            return _3630;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2147;\n    if (i == 0)\n    {\n        _2147 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2163;\n        if (i == 1)\n        {\n            _2163 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2171;\n            if (i == 2)\n            {\n                _2171 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2171 = fa_shadows[24].w;\n            }\n            _2163 = _2171;\n        }\n        _2147 = _2163;\n    }\n    return _2147;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2450 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2455 = clamp(dot(n, l), 0.0, 1.0);\n    float _2461 = sqrt(1.0 - (_2455 * _2455));\n    float _2469 = min(_2461 / max(_2455, 0.20000000298023223876953125), 4.0);\n    float _2474;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2474 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2474 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2499 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2474 * _2461)), 1.0);\n    float _2506 = _2499.x;\n    bool _2509 = _2506 < fa_shadows[ci * 1 + 16].x;\n    bool _2518;\n    if (!_2509)\n    {\n        _2518 = _2506 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2518 = _2509;\n    }\n    bool _2527;\n    if (!_2518)\n    {\n        _2527 = _2499.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2527 = _2518;\n    }\n    bool _2536;\n    if (!_2527)\n    {\n        _2536 = _2499.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2536 = _2527;\n    }\n    bool _2543;\n    if (!_2536)\n    {\n        _2543 = _2499.z > 1.0;\n    }\n    else\n    {\n        _2543 = _2536;\n    }\n    if (_2543)\n    {\n        return -1.0;\n    }\n    float _2551;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2551 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2551 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2499.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2499.z - ((_2551 * (1.0 + (0.5 * _2469))) / _2450);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2450;\n    float param_5 = _2450 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2469, 3.0)) * 0.5) / _2450;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2929 = int(fa_shadows[25].x + 0.5);\n    if (_2929 < 1)\n    {\n        return 1.0;\n    }\n    float _2944 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2929 - 1;\n    if (_2944 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2956 = _2929 > 1;\n    bool _2963;\n    if (_2956)\n    {\n        _2963 = _2944 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2963 = _2956;\n    }\n    if (_2963)\n    {\n        ci = 1;\n    }\n    bool _2967 = _2929 > 2;\n    bool _2974;\n    if (_2967)\n    {\n        _2974 = _2944 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2974 = _2967;\n    }\n    if (_2974)\n    {\n        ci = 2;\n    }\n    bool _2978 = _2929 > 3;\n    bool _2985;\n    if (_2978)\n    {\n        _2985 = _2944 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2985 = _2978;\n    }\n    if (_2985)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2996 = min(_2929, 4);\n    float _3037;\n    for (int c = ci; c < _2996; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3016 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3016;\n            break;\n        }\n        if (_3016 < 0.0)\n        {\n            continue;\n        }\n        s = _3016;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3037 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3037 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3056 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3037, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2944 - (fa_shadow_split_at(param_7) - _3056)) / _3056, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3088;\n        if ((ci + 1) < _2929)\n        {\n            _3088 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3088 = 1.0;\n        }\n        s = mix(s, _3088, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3193 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3199;\n    if (_3193)\n    {\n        _3199 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3199 = _3193;\n    }\n    if (_3199)\n    {\n        float _3213 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3216 = fwidth(_3213);\n        vec4 _3226 = vec4(fa_world_pos, 1.0);\n        float _3232 = dot(fa_mesh_fs_params[28], _3226);\n        if (_3232 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3251 = vec2(dot(fa_mesh_fs_params[26], _3226), dot(fa_mesh_fs_params[27], _3226)) / vec2(_3232);\n            float _3256 = (_3251.x * 0.5) + 0.5;\n            float _3260;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3260 = (_3251.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3260 = 0.5 - (_3251.y * 0.5);\n            }\n            bool _3276 = _3256 >= 0.0;\n            bool _3282;\n            if (_3276)\n            {\n                _3282 = _3256 < 1.0;\n            }\n            else\n            {\n                _3282 = _3276;\n            }\n            bool _3288;\n            if (_3282)\n            {\n                _3288 = _3260 >= 0.0;\n            }\n            else\n            {\n                _3288 = _3282;\n            }\n            bool _3294;\n            if (_3288)\n            {\n                _3294 = _3260 < 1.0;\n            }\n            else\n            {\n                _3294 = _3288;\n            }\n            if (_3294)\n            {\n                vec4 _3320 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3256, _3260) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3323 = _3320.w > 0.5;\n                bool _3339;\n                if (_3323)\n                {\n                    _3339 = abs(_3213 - _3320.x) <= (((0.00200000009499490261077880859375 * _3213) + 0.00999999977648258209228515625) + min(1.5 * _3216, 0.100000001490116119384765625 * _3213));\n                }\n                else\n                {\n                    _3339 = _3323;\n                }\n                if (_3339)\n                {\n                    float _3345;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3345 = min(_3320.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3345 = _3320.y;\n                    }\n                    return _3345;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5186 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5193;\n    if (!_5186)\n    {\n        _5193 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5193 = _5186;\n    }\n    if (_5193)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5206 = fa_light_texel(param);\n    float _5207 = _5206.y;\n    float len = _5207;\n    if (_5207 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5219 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5228 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5219);\n    if (_5228 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5234 = len;\n    float _5237 = min(_5234, 0.89999997615814208984375 * dist);\n    len = _5237;\n    float _5242 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5219);\n    float _5247 = _5242 + (0.5 * _5237);\n    vec3 _5253 = world + (gn * _5242);\n    float _5255 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5316;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5270 = (float(k) + _5255) * 0.083333335816860198974609375;\n        vec3 _5278 = _5253 + (l * (_5270 * len));\n        vec4 _5284 = vec4(_5278, 1.0);\n        float _5289 = dot(fa_mesh_fs_params[28], _5284);\n        if (_5289 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5307 = vec2(dot(fa_mesh_fs_params[26], _5284), dot(fa_mesh_fs_params[27], _5284)) / vec2(_5289);\n        float _5311 = _5307.x * 0.5;\n        float _5312 = _5311 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5316 = (_5307.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5316 = 0.5 - (_5307.y * 0.5);\n        }\n        bool _5332 = _5312 < 0.0;\n        bool _5339;\n        if (!_5332)\n        {\n            _5339 = _5312 >= 1.0;\n        }\n        else\n        {\n            _5339 = _5332;\n        }\n        bool _5346;\n        if (!_5339)\n        {\n            _5346 = _5316 < 0.0;\n        }\n        else\n        {\n            _5346 = _5339;\n        }\n        bool _5353;\n        if (!_5346)\n        {\n            _5353 = _5316 >= 1.0;\n        }\n        else\n        {\n            _5353 = _5346;\n        }\n        if (_5353)\n        {\n            break;\n        }\n        vec4 _5377 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5312, _5316) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5377.w < 0.5)\n        {\n            continue;\n        }\n        float _5395 = (dot(fa_mesh_fs_params[29].xyz, _5278) + fa_mesh_fs_params[29].w) - _5377.x;\n        if ((_5395 > _5242) && (_5395 < _5247))\n        {\n            occ = max(occ, (1.0 - (_5270 * _5270)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5312, 0.5 - _5311), min(_5316, 1.0 - _5316))));\n        }\n    }\n    return 1.0 - (occ * _5228);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5498 = fa_baked_keep(param);\n    if (_5498 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5524 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7402 = _5524.color;\n    float _7403 = _5524.attenuation;\n    float _7404 = _5524.shadow;\n    bool _5527 = _5524.type == 0;\n    if (_5527 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5524.direction;\n        float _5538 = fa_shadow_factor(param_5, param_6);\n        _7404 = _5538;\n        _7402 *= _5538;\n    }\n    else\n    {\n        bool _5549 = _5524.type != 0;\n        bool _5555;\n        if (_5549)\n        {\n            _5555 = _7403 > 0.0;\n        }\n        else\n        {\n            _5555 = _5549;\n        }\n        if (_5555)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5524.direction;\n            float _5574 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _7404 = _5574;\n            _7402 *= _5574;\n        }\n    }\n    bool _5584 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5590;\n    if (_5584)\n    {\n        _5590 = _7403 > 0.0;\n    }\n    else\n    {\n        _5590 = _5584;\n    }\n    if (_5590)\n    {\n        float _5597;\n        if (_5527)\n        {\n            _5597 = 1000000000.0;\n        }\n        else\n        {\n            _5597 = _5524._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5524.direction;\n        float param_18 = _5597;\n        float _5615 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7404 *= _5615;\n        _7402 *= _5615;\n    }\n    float _5628 = _7403;\n    float _5629 = _5628 * _5498;\n    _7403 = _5629;\n    vec3 _5633 = _7402;\n    vec3 _5634 = _5633 * _5498;\n    _7402 = _5634;\n    return LightSample(_5524.direction, _5634, _5629, _7404, _5524._distance, _5524.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3116 = int(fa_shadows[25].x + 0.5);\n    float _3126 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3131 = _3116 > 0;\n    bool _3140;\n    if (_3131)\n    {\n        int param = _3116 - 1;\n        _3140 = _3126 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3140 = _3131;\n    }\n    if (_3140)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3146 = _3116 > 1;\n        bool _3153;\n        if (_3146)\n        {\n            _3153 = _3126 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3153 = _3146;\n        }\n        if (_3153)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3159 = _3116 > 2;\n        bool _3166;\n        if (_3159)\n        {\n            _3166 = _3126 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3166 = _3159;\n        }\n        if (_3166)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3172 = _3116 > 3;\n        bool _3179;\n        if (_3172)\n        {\n            _3179 = _3126 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3179 = _3172;\n        }\n        if (_3179)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7087 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7087 = -_7087;\n    }\n    vec3 _6710 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7087, fa_world_tangent, fa_uv, fa_vertex_color, _6710, gl_FrontFacing);\n    Surface _6718 = fa_standard_surface(param_1);\n    vec3 _7126 = _6718.albedo;\n    float _7127 = _6718.alpha;\n    vec3 _7128 = _6718.normal;\n    float _7129 = _6718.metallic;\n    float _7130 = _6718.roughness;\n    float _7131 = _6718.occlusion;\n    vec3 _7132 = _6718.emission;\n    float _7133 = _6718.clearcoat;\n    float _7134 = _6718.clearcoat_roughness;\n    vec3 _7135 = _6718.sheen_color;\n    float _7136 = _6718.sheen_roughness;\n    float _7137 = _6718.anisotropy;\n    float _7138 = _6718.anisotropy_rotation;\n    float _7139 = _6718.specular;\n    float _7140 = _6718.ior;\n    vec3 _7141 = _6718.specular_color;\n    float _7142 = _6718.transmission;\n    float _7143 = _6718.thickness;\n    vec3 _7144 = _6718.attenuation_color;\n    float _7145 = _6718.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7087, fa_world_tangent, fa_uv, fa_vertex_color, _6710, gl_FrontFacing);\n    Surface param_3 = _6718;\n    surface(param_2, param_3);\n    _7126 = param_3.albedo;\n    _7127 = param_3.alpha;\n    _7128 = param_3.normal;\n    _7129 = param_3.metallic;\n    _7130 = param_3.roughness;\n    _7131 = param_3.occlusion;\n    _7132 = param_3.emission;\n    _7133 = param_3.clearcoat;\n    _7134 = param_3.clearcoat_roughness;\n    _7135 = param_3.sheen_color;\n    _7136 = param_3.sheen_roughness;\n    _7137 = param_3.anisotropy;\n    _7138 = param_3.anisotropy_rotation;\n    _7139 = param_3.specular;\n    _7140 = param_3.ior;\n    _7141 = param_3.specular_color;\n    _7142 = param_3.transmission;\n    _7143 = param_3.thickness;\n    _7144 = param_3.attenuation_color;\n    _7145 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7087;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7126 = param_6;\n    _7128 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7126;\n    }\n    else\n    {\n        vec3 _6757 = _7128;\n        vec3 _6758 = normalize(_6757);\n        _7128 = _6758;\n        vec3 param_8 = _6758;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _7087, fa_world_tangent, fa_uv, fa_vertex_color, _6710, gl_FrontFacing);\n        Surface param_10 = Surface(_7126, _7127, _7128, _7129, _7130, _7131, _7132, _7133, _7134, _7135, _7136, _7137, _7138, _7139, _7140, _7141, _7142, _7143, _7144, _7145);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6777 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6777; ln++)\n        {\n            int param_12 = ln;\n            int _6790 = fa_cl_light(param_12);\n            int param_13 = _6790;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6790;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _7087;\n            LightSample _6806 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _7087, fa_world_tangent, fa_uv, fa_vertex_color, _6710, gl_FrontFacing);\n            Surface param_18 = Surface(_7126, _7127, _7128, _7129, _7130, _7131, _7132, _7133, _7134, _7135, _7136, _7137, _7138, _7139, _7140, _7141, _7142, _7143, _7144, _7145);\n            LightSample param_19 = _6806;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6821 = result;\n    vec3 _6822 = _6821 + _7132;\n    result = _6822;\n    vec3 param_20 = _6822;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6831 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6838;\n    if (!_6831)\n    {\n        _6838 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6838 = _6831;\n    }\n    if (_6838)\n    {\n        vec3 _6847 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6853 = dot(_6847, fa_mesh_fs_params[9].xyz);\n        bool _6857 = fa_mesh_fs_params[9].w > 0.5;\n        float _6858;\n        if (_6857)\n        {\n            _6858 = _6853;\n        }\n        else\n        {\n            _6858 = length(_6847);\n        }\n        float _6870 = _6858 - fa_mesh_fs_params[8].x;\n        if (_6870 > 0.0)\n        {\n            float _6879 = fa_mesh_fs_params[7].w * _6870;\n            float tau = _6879 * _6879;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6895;\n                if (_6857)\n                {\n                    _6895 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6853);\n                }\n                else\n                {\n                    _6895 = fa_mesh_fs_params[0].y;\n                }\n                float _6916 = mix(_6895, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6858, 0.0, 1.0));\n                float _6920 = fa_world_pos.y - _6916;\n                float _6925 = _6916 - fa_mesh_fs_params[8].z;\n                float _6930 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6933 = _6925 <= 0.0;\n                bool _6934 = !_6933;\n                bool _6940;\n                if (_6934)\n                {\n                    _6940 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6940 = _6933;\n                }\n                float _6941;\n                if (_6940)\n                {\n                    _6941 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6941 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6925, 80.0));\n                }\n                bool _6968;\n                if (_6934)\n                {\n                    _6968 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6968 = _6933;\n                }\n                float _6969;\n                if (_6968)\n                {\n                    _6969 = fa_mesh_fs_params[8].y * _6925;\n                }\n                else\n                {\n                    _6969 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6925, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6994 = _6930 <= 0.0;\n                bool _7001;\n                if (!_6994)\n                {\n                    _7001 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7001 = _6994;\n                }\n                float _7002;\n                if (_7001)\n                {\n                    _7002 = fa_mesh_fs_params[8].y * _6930;\n                }\n                else\n                {\n                    _7002 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6930, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7029;\n                if (abs(_6920) < 0.001000000047497451305389404296875)\n                {\n                    _7029 = _6941;\n                }\n                else\n                {\n                    _7029 = (_7002 - _6969) / _6920;\n                }\n                tau += (_6870 * max(_7029, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7127);\n}\n\n",
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
            "inst_name": "_505",
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
            "inst_name": "_2157",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _455 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_455, 1.0);\n    fa_world_pos = _455;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_455 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _720 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_720, 1.0);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_720 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
    }
  }
}

{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4353[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1406 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1413;\n    if (!_1406)\n    {\n        _1413 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1413 = _1406;\n    }\n    bool _1421;\n    if (!_1413)\n    {\n        _1421 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1421 = _1413;\n    }\n    bool _1428;\n    if (!_1421)\n    {\n        _1428 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1428 = _1421;\n    }\n    bool _1435;\n    if (!_1428)\n    {\n        _1435 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1435 = _1428;\n    }\n    if (_1435)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1445 = vec4(world_pos, 1.0);\n    float _1451 = dot(fa_mesh_fs_params[16], _1445);\n    if (!(_1451 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1473 = vec2(dot(fa_mesh_fs_params[14], _1445), dot(fa_mesh_fs_params[15], _1445)) / vec2(_1451);\n    int _1477 = int(fa_mesh_fs_params[18].x);\n    int _1481 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1481) + clamp(int(floor(((_1473.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1481 - 1)) * _1477)) + clamp(int(floor(((_1473.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1477 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1557 = fa_cluster_texel(param);\n    return ivec2(int(_1557.x), int(_1557.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _5178 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _5181 = fwidth(_5178);\n    bool _5184 = fa_mesh_fs_params[25].y > 0.5;\n    bool _5191;\n    if (!_5184)\n    {\n        _5191 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _5191 = _5184;\n    }\n    if (_5191)\n    {\n        fa_rt_slope = min(1.5 * _5181, 0.100000001490116119384765625 * _5178);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5207 = fa_cluster_lookup(param);\n    fa_cl_slot = _5207.x;\n    fa_cl_local = _5207.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5584 = fa_linear_to_srgb(param);\n        c = _5584;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5592 = fa_srgb_to_linear(param_1);\n            c = _5592;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _358;\n    if (i.front_facing)\n    {\n        _358 = i.world_normal;\n    }\n    else\n    {\n        _358 = -i.world_normal;\n    }\n    vec3 _382 = normalize(i.world_tangent.xyz - (_358 * dot(_358, i.world_tangent.xyz)));\n    vec3 _410 = normalize(((_382 * m.x) + ((cross(_358, _382) * i.world_tangent.w) * m.y)) + (_358 * m.z));\n    vec3 _413;\n    if (i.front_facing)\n    {\n        _413 = _410;\n    }\n    else\n    {\n        _413 = -_410;\n    }\n    return _413;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5624 = fa_tex_fix(param_2, param_3);\n    vec4 _6792 = base_t;\n    _6792.x = _5624.x;\n    _6792.y = _5624.y;\n    _6792.z = _5624.z;\n    base_t = _6792;\n    vec4 _5638 = (_6792 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6577 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5672 = fa_tex_fix(param_6, param_7);\n        vec3 _5675 = (_5672 * 2.0) - vec3(1.0);\n        vec2 _5680 = _5675.xy * fa_mesh_fs_params[6].x;\n        vec3 _6800 = _5675;\n        _6800.x = _5680.x;\n        _6800.y = _5680.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6800;\n        _6577 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5710 = fa_tex_fix(param_12, param_13);\n    vec4 _6803 = mrt;\n    _6803.x = _5710.x;\n    _6803.y = _5710.y;\n    _6803.z = _5710.z;\n    mrt = _6803;\n    vec4 _5740 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5740.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5751 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5783 = fa_tex_fix(param_20, param_21);\n    float _6582 = fa_mesh_fs_params[20].x;\n    float _6583 = fa_mesh_fs_params[20].y;\n    float _6586 = fa_mesh_fs_params[20].z;\n    float _6585 = fa_mesh_fs_params[21].w;\n    float _6588 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6582 *= _5751.y;\n            _6583 *= _5751.z;\n            _6585 *= _5740.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6586 *= mrt.x;\n            _6588 *= mrt.w;\n        }\n    }\n    return Surface(_5638.xyz, _5638.w, _6577, clamp(fa_mesh_fs_params[5].x * _5710.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5710.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5751.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5783), _6582, _6583, fa_mesh_fs_params[21].xyz, _6585, _6586, fa_mesh_fs_params[20].w, _6588, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1637 = rect.zw - rect.xy;\n    vec2 _1641 = _1637 * atlas;\n    vec2 _1645 = ddx * _1641;\n    vec2 _1649 = ddy * _1641;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1637), clamp(0.5 * log2(max(max(dot(_1645, _1645), dot(_1649, _1649)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1682 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1689;\n    if (!_1682)\n    {\n        _1689 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1689 = _1682;\n    }\n    if (_1689)\n    {\n        return;\n    }\n    vec3 _1695 = dFdx(world_pos);\n    vec3 _1698 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1702 = fa_cluster_texel(param);\n    int _1706 = int(_1702.w);\n    if (_1706 < 1)\n    {\n        return;\n    }\n    int _1716 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1716;\n    vec4 _1720 = fa_light_texel(param_1);\n    vec2 _1723 = _1720.yz;\n    int _1727 = int(_1720.w);\n    int param_2 = _1716 + 1;\n    vec4 _1732 = fa_light_texel(param_2);\n    float _1733 = _1732.x;\n    int _1739 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1743 = int(_1702.z);\n    vec3 _2008;\n    for (int k = 0; k < _1706; k++)\n    {\n        int _1756 = _1743 + k;\n        int param_3 = _1727 + (_1756 >> 2);\n        int _1773 = (_1716 + 2) + (int(fa_light_texel(param_3)[_1756 & 3]) * 7);\n        int param_4 = _1773 + 6;\n        vec4 _1778 = fa_light_texel(param_4);\n        if (((int(_1778.w + 0.5) >> _1739) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1773;\n        vec4 _1793 = fa_light_texel(param_5);\n        int param_6 = _1773 + 1;\n        vec4 _1798 = fa_light_texel(param_6);\n        int param_7 = _1773 + 2;\n        vec4 _1803 = fa_light_texel(param_7);\n        vec3 _1806 = _1793.xyz;\n        float _1811 = dot(_1806, world_pos) + _1793.w;\n        vec3 _1813 = _1798.xyz;\n        float _1818 = dot(_1813, world_pos) + _1798.w;\n        vec3 _1820 = _1803.xyz;\n        float _1825 = dot(_1820, world_pos) + _1803.w;\n        bool _1830 = abs(_1811) > 0.5;\n        bool _1838;\n        if (!_1830)\n        {\n            _1838 = abs(_1818) > 0.5;\n        }\n        else\n        {\n            _1838 = _1830;\n        }\n        bool _1846;\n        if (!_1838)\n        {\n            _1846 = abs(_1825) > 0.5;\n        }\n        else\n        {\n            _1846 = _1838;\n        }\n        if (_1846)\n        {\n            continue;\n        }\n        float _1861 = clamp(dot(geo_normal, normalize(_1820)) * _1778.z, 0.0, 1.0);\n        if (_1861 <= 0.0)\n        {\n            continue;\n        }\n        float _1881 = (clamp((0.5 - abs(_1825)) * 10.0, 0.0, 1.0) * _1861) * _1778.x;\n        vec2 _1889 = vec2(_1811 + 0.5, 0.5 - _1818);\n        vec2 _1899 = vec2(dot(_1806, _1695), dot(_1813, _1695));\n        vec2 _1909 = vec2(dot(_1806, _1698), dot(_1813, _1698));\n        int param_8 = _1773 + 5;\n        vec4 _1914 = fa_light_texel(param_8);\n        int param_9 = _1773 + 3;\n        vec4 _1919 = fa_light_texel(param_9);\n        int param_10 = _1773 + 4;\n        vec4 _1924 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1914.xyz;\n        bool _1934 = _1919.z > _1919.x;\n        if (_1934)\n        {\n            vec4 param_11 = _1919;\n            vec2 param_12 = _1889;\n            vec2 param_13 = _1723;\n            vec2 param_14 = _1899;\n            vec2 param_15 = _1909;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1733 > 0.5) && (_1733 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1960 = fa_dc_to_linear(param_16);\n                vec4 _6665 = tx;\n                _6665.x = _1960.x;\n                _6665.y = _1960.y;\n                _6665.z = _1960.z;\n                tx = _6665;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1881 * tex_a) * _1914.w, 0.0, 1.0)));\n        if (_1924.z > _1924.x)\n        {\n            vec4 param_17 = _1924;\n            vec2 param_18 = _1889;\n            vec2 param_19 = _1723;\n            vec2 param_20 = _1899;\n            vec2 param_21 = _1909;\n            vec4 _2004 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1733 > 1.5)\n            {\n                vec3 param_22 = _2004.xyz;\n                vec3 _2014 = fa_dc_to_srgb(param_22);\n                _2008 = _2014;\n            }\n            else\n            {\n                _2008 = _2004.xyz;\n            }\n            vec3 _2023 = (_2008 * 2.0) - vec3(1.0);\n            vec2 _2028 = _2023.xy * _1778.y;\n            vec3 _2050 = (normalize(_1806) * _2028.x) + (normalize(_1813) * _2028.y);\n            vec3 _2053 = normalize(normal);\n            normal = normalize(mix(_2053, normalize((_2053 * max(_2023.z, 0.0500000007450580596923828125)) + (_2050 - (_2053 * dot(_2053, _2050)))), vec3(clamp(_1881 * (_1934 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5148;\n    if (fa_lm.z > 0.5)\n    {\n        _5148 = 0.0;\n    }\n    else\n    {\n        _5148 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5159 = _5148 < 1.0;\n    bool _5165;\n    if (_5159)\n    {\n        int param = li;\n        _5165 = fa_light_baked(param);\n    }\n    else\n    {\n        _5165 = _5159;\n    }\n    return _5165 ? _5148 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _655 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _668 = (c - (ru * hx)) - p;\n        vec3 _674 = ru * (2.0 * hx);\n        float _680 = max(dot(_674, _674), 9.9999999392252902907785028219223e-09);\n        float _684 = dot(_668, _674);\n        float t = clamp((-_684) / _680, 0.0, 1.0);\n        if (_655)\n        {\n            float _699 = dot(r, _674);\n            float _705 = _680 - (_699 * _699);\n            if (abs(_705) > (9.9999997473787516355514526367188e-06 * _680))\n            {\n                t = clamp(((dot(r, _668) * _699) - _684) / _705, 0.0, 1.0);\n            }\n        }\n        return (p + _668) + (_674 * t);\n    }\n    vec3 q = p;\n    float _737 = dot(r, axis);\n    bool _745;\n    if (_655)\n    {\n        _745 = abs(_737) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _745 = _655;\n    }\n    if (_745)\n    {\n        float _755 = dot(c - p, axis) / _737;\n        if (_755 > 0.0)\n        {\n            q = p + (r * _755);\n        }\n    }\n    vec3 _768 = q - c;\n    vec2 xy = vec2(dot(_768, ru), dot(_768, uu));\n    if (shape > 0.5)\n    {\n        float _783 = length(xy);\n        if (_783 > hx)\n        {\n            xy *= (hx / _783);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _575 = dot(d, right);\n    float _579 = dot(d, up);\n    float _590;\n    if (((_575 * _575) + (_579 * _579)) > 1.0000000133514319600180897396058e-10)\n    {\n        _590 = atan(_579, _575) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _590 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_590 - floor(_590)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _425 = abs(d);\n    float _427 = _425.x;\n    float _429 = _425.y;\n    bool _430 = _427 >= _429;\n    bool _438;\n    if (_430)\n    {\n        _438 = _427 >= _425.z;\n    }\n    else\n    {\n        _438 = _430;\n    }\n    int _439;\n    if (_438)\n    {\n        _439 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _453;\n        if (_429 >= _425.z)\n        {\n            _453 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _453 = (d.z > 0.0) ? 4 : 5;\n        }\n        _439 = _453;\n    }\n    return _439;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _821 = fa_light_base(param);\n    bool _825 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _821;\n    vec4 _829 = fa_light_texel(param_1);\n    int param_2 = _821 + 1;\n    vec4 _834 = fa_light_texel(param_2);\n    float _837 = _834.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _849 = _825 && (_837 > 2.5);\n    fa_light_is_area = _849;\n    bool _851 = _837 < 0.5;\n    vec3 l;\n    if (_851)\n    {\n        l = normalize(_829.xyz);\n        if (_825)\n        {\n            int param_3 = _821 + 6;\n            vec4 _865 = fa_light_texel(param_3);\n            if (_865.z > 0.5)\n            {\n                int param_4 = _821 + 4;\n                vec4 _875 = fa_light_texel(param_4);\n                int param_5 = _821 + 5;\n                vec4 _880 = fa_light_texel(param_5);\n                vec2 param_6 = _865.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _875.xyz) * _875.w, (-dot(world_pos, _880.xyz)) * _880.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _910 = _829.xyz;\n        vec3 _912 = _910 - world_pos;\n        vec3 to_light = _912;\n        float _915 = length(_912);\n        float reach = _915;\n        bool front = true;\n        if (_849)\n        {\n            int param_8 = _821 + 7;\n            reach = max(_915 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _821 + 4;\n            vec4 _939 = fa_light_texel(param_9);\n            int param_10 = _821 + 5;\n            vec4 _944 = fa_light_texel(param_10);\n            int param_11 = _821 + 6;\n            vec4 _949 = fa_light_texel(param_11);\n            float _950 = _949.w;\n            int param_12 = _821 + 2;\n            vec3 _957 = normalize(fa_light_texel(param_12).xyz);\n            bool _959 = _950 > 1.5;\n            bool _967;\n            if (!_959)\n            {\n                _967 = dot(_957, to_light) < 0.0;\n            }\n            else\n            {\n                _967 = _959;\n            }\n            front = _967;\n            vec3 r = vec3(0.0);\n            vec3 _976 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _980 = dot(n, n) > 0.5;\n            bool _988;\n            if (_980)\n            {\n                _988 = dot(_976, _976) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _988 = _980;\n            }\n            if (_988)\n            {\n                r = reflect(-normalize(_976), normalize(n));\n            }\n            vec3 param_13 = _910;\n            vec3 param_14 = _957;\n            vec3 param_15 = _939.xyz;\n            vec3 param_16 = _944.xyz;\n            float param_17 = _939.w;\n            float param_18 = _944.w;\n            float param_19 = _950;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1024 = length(to_light);\n        dist = _1024;\n        l = to_light / vec3(max(_1024, 9.9999997473787516355514526367188e-05));\n        float _1038 = reach / max(_829.w, 0.001000000047497451305389404296875);\n        float _1044 = clamp(1.0 - (_1038 * _1038), 0.0, 1.0);\n        float _1046;\n        if (front)\n        {\n            _1046 = _1044 * _1044;\n        }\n        else\n        {\n            _1046 = 0.0;\n        }\n        atten = _1046;\n        bool _1057 = _837 < 2.5;\n        if ((_837 > 1.5) && _1057)\n        {\n            int param_22 = _821 + 2;\n            vec4 _1065 = fa_light_texel(param_22);\n            float _1075 = _1065.w;\n            int param_23 = _821 + 3;\n            vec4 _1080 = fa_light_texel(param_23);\n            float _1081 = _1080.x;\n            float cos_inner = _1081;\n            if (_1081 > 1.5)\n            {\n                cos_inner = mix(_1075, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1075, cos_inner, dot(-l, normalize(_1065.xyz)));\n        }\n        if (_825 && (_837 < 1.5))\n        {\n            int param_24 = _821 + 6;\n            vec4 _1105 = fa_light_texel(param_24);\n            if (_1105.z > 0.5)\n            {\n                vec3 _1113 = -to_light;\n                int param_25 = _821 + 4;\n                int param_26 = _821 + 5;\n                vec3 _1127 = fa_light_texel(param_25).xyz;\n                vec3 _1131 = fa_light_texel(param_26).xyz;\n                vec3 _1140 = vec3(dot(_1113, _1127), dot(_1113, _1131), dot(_1113, cross(_1127, _1131)));\n                vec3 param_27 = _1140;\n                int _1144 = fa_cube_face(param_27);\n                int param_28 = _1144;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1171 = vec2(dot(_1140, cross(param_29, param_30)), dot(_1140, param_30)) / vec2(max(dot(_1140, param_29), 9.9999997473787516355514526367188e-05));\n                int _1175 = _1144 / 3;\n                vec2 param_31 = _1105.xy + (vec2(float(_1144 - (_1175 * 3)), float(_1175)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1171.x), 0.5 - (0.5 * _1171.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _821 + 7;\n            vec4 _1205 = fa_light_texel(param_33);\n            if (_1205.z > 0.5)\n            {\n                int param_34 = _821 + 2;\n                int param_35 = _821 + 4;\n                int param_36 = _821 + 5;\n                vec2 param_37 = _1205.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_825 && _1057)\n            {\n                int param_42 = _821 + 6;\n                vec4 _1252 = fa_light_texel(param_42);\n                int param_43 = _821 + 7;\n                vec4 _1257 = fa_light_texel(param_43);\n                bool _1260 = _1252.z > 0.5;\n                bool _1267;\n                if (!_1260)\n                {\n                    _1267 = _1257.z > 0.5;\n                }\n                else\n                {\n                    _1267 = _1260;\n                }\n                if (_1267)\n                {\n                    int param_44 = _821 + 2;\n                    vec4 _1274 = fa_light_texel(param_44);\n                    vec3 _1278 = normalize(_1274.xyz);\n                    int param_45 = _821 + 4;\n                    vec4 _1283 = fa_light_texel(param_45);\n                    int param_46 = _821 + 5;\n                    vec4 _1288 = fa_light_texel(param_46);\n                    if (_1260)\n                    {\n                        vec3 _1296 = -to_light;\n                        float _1303 = _1274.w;\n                        float _1319 = 0.5 / max(dot(_1296, _1278) * (sqrt(max(1.0 - (_1303 * _1303), 0.0)) / max(_1303, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1252.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1296, _1283.xyz) * _1319), 0.5 - (dot(_1296, _1288.xyz) * _1319));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1257.z > 0.5)\n                    {\n                        vec2 param_49 = _1257.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1278;\n                        vec3 param_52 = _1283.xyz;\n                        vec3 param_53 = _1288.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6383 = _834.xyz * atten;\n    if (_825)\n    {\n        _6383 *= fa_light_tint;\n    }\n    int _1388;\n    if (_851)\n    {\n        _1388 = 0;\n    }\n    else\n    {\n        _1388 = ((_837 > 1.5) && (_837 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6383, atten, 1.0, dist, _1388);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5406 = n < 0;\n    bool _5413;\n    if (!_5406)\n    {\n        _5413 = n >= fa_light_count();\n    }\n    else\n    {\n        _5413 = _5406;\n    }\n    if (_5413)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5421 = fa_cl_light(param);\n    int param_1 = _5421;\n    float _5425 = fa_baked_keep(param_1);\n    if (_5425 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5421;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5441 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5441.direction, _5441.color * _5425, _5441.attenuation * _5425, _5441.shadow, _5441._distance, _5441.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2177 = fa_shadow_depth(param, param_1);\n    float _2181;\n    if (conv.x < 0.5)\n    {\n        _2181 = _2177;\n    }\n    else\n    {\n        _2181 = (conv.y * conv.z) / (conv.z - (_2177 * (conv.z - conv.y)));\n    }\n    return _2181;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2227 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2233 = vec2(cos(_2227), sin(_2227));\n    vec2 dir = _2233;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2242;\n        if (k < 0.0)\n        {\n            _2242 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2242 = k;\n        }\n        float _2261 = clamp((_2242 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2280 = sqrt((float(i) + 0.5) * 0.0625) * _2261;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2280));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2294 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2294 < (zr - (_2280 * plane)))\n            {\n                sum += _2294;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2322 = sum / cnt;\n        float _2332;\n        if (k < 0.0)\n        {\n            _2332 = (-k) / max(_2322, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2332 = k;\n        }\n        radius = clamp(((max(zr - _2322, 0.0) * unit) * _2332) / texel_m, 1.5, 16.0);\n        dir = _2233;\n    }\n    float lit = 0.0;\n    int _2358 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2358; i_1++)\n    {\n        float _2377 = sqrt((float(i_1) + 0.5) / float(_2358)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2377));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2377 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2358);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2582 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2589;\n    if (!_2582)\n    {\n        _2589 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2589 = _2582;\n    }\n    if (_2589)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2602 = fa_light_texel(param);\n    float _2603 = _2602.x;\n    if (_2603 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2612 = int(_2603 + 0.5);\n    int param_1 = _2612;\n    vec4 _2616 = fa_light_texel(param_1);\n    int param_2 = _2612 + 1;\n    vec4 _2621 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2624 = _2616.y;\n    if (_2624 > 0.0)\n    {\n        float _2641 = 1.0 - smoothstep(0.75 * _2624, _2624, length(world - fa_shadows[27].xyz));\n        fade = _2641;\n        if (_2641 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2616.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2665 = (_2612 + 2) + (face * 6);\n    int param_4 = _2665;\n    int param_5 = _2665 + 1;\n    int param_6 = _2665 + 3;\n    vec4 _2679 = fa_light_texel(param_6);\n    int param_7 = _2665 + 4;\n    vec4 _2684 = fa_light_texel(param_7);\n    int param_8 = _2665 + 5;\n    vec4 _2689 = fa_light_texel(param_8);\n    float _2701 = _2689.x * max(dot(_2679, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2706 = clamp(dot(n, l), 0.0, 1.0);\n    float _2729 = clamp(dot(n, _2679.xyz), -1.0, 1.0);\n    float _2748 = min(sqrt(1.0 - (_2729 * _2729)) / max(abs(dot(n, world - lpos)) / max(dot(_2679, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2751 = _2621.y;\n    float _2753;\n    if (_2751 > 0.0)\n    {\n        _2753 = _2751;\n    }\n    else\n    {\n        _2753 = 1.5 * _2701;\n    }\n    vec4 _2773 = vec4(world + (n * (_2753 * sqrt(1.0 - (_2706 * _2706)))), 1.0);\n    float _2777 = dot(_2679, _2773);\n    float _2780 = _2689.y;\n    if (_2777 < _2780)\n    {\n        return 1.0;\n    }\n    vec2 _2795 = vec2(dot(fa_light_texel(param_4), _2773), dot(fa_light_texel(param_5), _2773)) / vec2(_2777);\n    float _2797 = _2795.x;\n    bool _2800 = _2797 < _2684.x;\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2797 > _2684.z;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2795.y < _2684.y;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    bool _2827;\n    if (!_2818)\n    {\n        _2827 = _2795.y > _2684.w;\n    }\n    else\n    {\n        _2827 = _2818;\n    }\n    if (_2827)\n    {\n        return 1.0;\n    }\n    float _2833 = _2621.x;\n    float _2835;\n    if (_2833 > 0.0)\n    {\n        _2835 = _2833;\n    }\n    else\n    {\n        _2835 = 1.5 * _2701;\n    }\n    vec2 param_9 = _2795;\n    vec4 param_10 = _2684;\n    float param_11 = _2777 - (_2835 * (1.0 + (0.5 * _2748)));\n    float param_12 = _2701;\n    float param_13 = 1.0;\n    float param_14 = _2689.z * 0.25;\n    float param_15 = (_2701 * min(_2748, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2780, _2689.z);\n    int param_17 = int(_2616.z + 0.5);\n    float param_18 = _2616.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3342 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3348;\n    if (_3342)\n    {\n        _3348 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3348 = _3342;\n    }\n    bool _3354;\n    if (_3348)\n    {\n        _3354 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3354 = _3348;\n    }\n    if (_3354)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3366 = fa_light_texel(param);\n        float _3367 = _3366.z;\n        if (_3367 > 0.5)\n        {\n            float _3380 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3386 = ((0.00200000009499490261077880859375 * _3380) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3392 = vec4(world, 1.0);\n            float _3397 = dot(fa_mesh_fs_params[28], _3392);\n            if (_3397 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3414 = vec2(dot(fa_mesh_fs_params[26], _3392), dot(fa_mesh_fs_params[27], _3392)) / vec2(_3397);\n                float _3419 = (_3414.x * 0.5) + 0.5;\n                float _3423;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3423 = (_3414.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3423 = 0.5 - (_3414.y * 0.5);\n                }\n                bool _3439 = _3419 >= 0.0;\n                bool _3445;\n                if (_3439)\n                {\n                    _3445 = _3419 < 1.0;\n                }\n                else\n                {\n                    _3445 = _3439;\n                }\n                bool _3451;\n                if (_3445)\n                {\n                    _3451 = _3423 >= 0.0;\n                }\n                else\n                {\n                    _3451 = _3445;\n                }\n                bool _3457;\n                if (_3451)\n                {\n                    _3457 = _3423 < 1.0;\n                }\n                else\n                {\n                    _3457 = _3451;\n                }\n                if (_3457)\n                {\n                    ivec2 _3474 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3475 = clamp(ivec2(vec2(_3419, _3423) * fa_mesh_fs_params[24].zw), ivec2(0), _3474);\n                    float _3479;\n                    if (_3367 < 1.5)\n                    {\n                        _3479 = 1.0;\n                    }\n                    else\n                    {\n                        _3479 = (_3367 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3501;\n                    int _3507;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3501 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3507 = k - 1;\n                            }\n                            else\n                            {\n                                _3507 = k;\n                            }\n                            _3501 = _3507;\n                        }\n                        vec4 _3536 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3475 + ivec2((_3501 % 3) - 1, (_3501 / 3) - 1), ivec2(0), _3474), 0);\n                        bool _3539 = _3536.w > 0.5;\n                        bool _3549;\n                        if (_3539)\n                        {\n                            _3549 = abs(_3380 - _3536.x) <= _3386;\n                        }\n                        else\n                        {\n                            _3549 = _3539;\n                        }\n                        if (_3549)\n                        {\n                            best = min(best, mod(floor(_3536.z / _3479), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3576;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3576 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3576 = best;\n                        }\n                        return _3576;\n                    }\n                }\n            }\n            float _3599;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3599 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3599 = 1.0;\n            }\n            return _3599;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2120;\n    if (i == 0)\n    {\n        _2120 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2136;\n        if (i == 1)\n        {\n            _2136 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2144;\n            if (i == 2)\n            {\n                _2144 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2144 = fa_shadows[24].w;\n            }\n            _2136 = _2144;\n        }\n        _2120 = _2136;\n    }\n    return _2120;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2423 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2428 = clamp(dot(n, l), 0.0, 1.0);\n    float _2434 = sqrt(1.0 - (_2428 * _2428));\n    float _2442 = min(_2434 / max(_2428, 0.20000000298023223876953125), 4.0);\n    float _2447;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2447 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2447 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2472 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2447 * _2434)), 1.0);\n    float _2479 = _2472.x;\n    bool _2482 = _2479 < fa_shadows[ci * 1 + 16].x;\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2479 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2472.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2509;\n    if (!_2500)\n    {\n        _2509 = _2472.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2509 = _2500;\n    }\n    bool _2516;\n    if (!_2509)\n    {\n        _2516 = _2472.z > 1.0;\n    }\n    else\n    {\n        _2516 = _2509;\n    }\n    if (_2516)\n    {\n        return -1.0;\n    }\n    float _2524;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2524 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2524 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2472.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2472.z - ((_2524 * (1.0 + (0.5 * _2442))) / _2423);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2423;\n    float param_5 = _2423 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2442, 3.0)) * 0.5) / _2423;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2902 = int(fa_shadows[25].x + 0.5);\n    if (_2902 < 1)\n    {\n        return 1.0;\n    }\n    float _2917 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2902 - 1;\n    if (_2917 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2929 = _2902 > 1;\n    bool _2936;\n    if (_2929)\n    {\n        _2936 = _2917 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2936 = _2929;\n    }\n    if (_2936)\n    {\n        ci = 1;\n    }\n    bool _2940 = _2902 > 2;\n    bool _2947;\n    if (_2940)\n    {\n        _2947 = _2917 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2947 = _2940;\n    }\n    if (_2947)\n    {\n        ci = 2;\n    }\n    bool _2951 = _2902 > 3;\n    bool _2958;\n    if (_2951)\n    {\n        _2958 = _2917 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2958 = _2951;\n    }\n    if (_2958)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2969 = min(_2902, 4);\n    float _3010;\n    for (int c = ci; c < _2969; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2989 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2989;\n            break;\n        }\n        if (_2989 < 0.0)\n        {\n            continue;\n        }\n        s = _2989;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3010 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3010 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3029 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3010, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2917 - (fa_shadow_split_at(param_7) - _3029)) / _3029, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3061;\n        if ((ci + 1) < _2902)\n        {\n            _3061 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3061 = 1.0;\n        }\n        s = mix(s, _3061, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3166 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3172;\n    if (_3166)\n    {\n        _3172 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3172 = _3166;\n    }\n    if (_3172)\n    {\n        float _3186 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3194 = vec4(fa_world_pos, 1.0);\n        float _3200 = dot(fa_mesh_fs_params[28], _3194);\n        if (_3200 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3219 = vec2(dot(fa_mesh_fs_params[26], _3194), dot(fa_mesh_fs_params[27], _3194)) / vec2(_3200);\n            float _3224 = (_3219.x * 0.5) + 0.5;\n            float _3228;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3228 = (_3219.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3228 = 0.5 - (_3219.y * 0.5);\n            }\n            bool _3244 = _3224 >= 0.0;\n            bool _3250;\n            if (_3244)\n            {\n                _3250 = _3224 < 1.0;\n            }\n            else\n            {\n                _3250 = _3244;\n            }\n            bool _3256;\n            if (_3250)\n            {\n                _3256 = _3228 >= 0.0;\n            }\n            else\n            {\n                _3256 = _3250;\n            }\n            bool _3262;\n            if (_3256)\n            {\n                _3262 = _3228 < 1.0;\n            }\n            else\n            {\n                _3262 = _3256;\n            }\n            if (_3262)\n            {\n                vec4 _3288 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3224, _3228) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3291 = _3288.w > 0.5;\n                bool _3307;\n                if (_3291)\n                {\n                    _3307 = abs(_3186 - _3288.x) <= (((0.00200000009499490261077880859375 * _3186) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3307 = _3291;\n                }\n                if (_3307)\n                {\n                    float _3313;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3313 = min(_3288.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3313 = _3288.y;\n                    }\n                    return _3313;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4892 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4899;\n    if (!_4892)\n    {\n        _4899 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4899 = _4892;\n    }\n    if (_4899)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4912 = fa_light_texel(param);\n    float _4913 = _4912.y;\n    float len = _4913;\n    if (_4913 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4925 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4934 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4925);\n    if (_4934 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4940 = len;\n    float _4943 = min(_4940, 0.89999997615814208984375 * dist);\n    len = _4943;\n    float _4948 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4925);\n    float _4953 = _4948 + (0.5 * _4943);\n    vec3 _4959 = world + (gn * _4948);\n    float _4961 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5022;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4976 = (float(k) + _4961) * 0.083333335816860198974609375;\n        vec3 _4984 = _4959 + (l * (_4976 * len));\n        vec4 _4990 = vec4(_4984, 1.0);\n        float _4995 = dot(fa_mesh_fs_params[28], _4990);\n        if (_4995 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5013 = vec2(dot(fa_mesh_fs_params[26], _4990), dot(fa_mesh_fs_params[27], _4990)) / vec2(_4995);\n        float _5017 = _5013.x * 0.5;\n        float _5018 = _5017 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5022 = (_5013.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5022 = 0.5 - (_5013.y * 0.5);\n        }\n        bool _5038 = _5018 < 0.0;\n        bool _5045;\n        if (!_5038)\n        {\n            _5045 = _5018 >= 1.0;\n        }\n        else\n        {\n            _5045 = _5038;\n        }\n        bool _5052;\n        if (!_5045)\n        {\n            _5052 = _5022 < 0.0;\n        }\n        else\n        {\n            _5052 = _5045;\n        }\n        bool _5059;\n        if (!_5052)\n        {\n            _5059 = _5022 >= 1.0;\n        }\n        else\n        {\n            _5059 = _5052;\n        }\n        if (_5059)\n        {\n            break;\n        }\n        vec4 _5083 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5018, _5022) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5083.w < 0.5)\n        {\n            continue;\n        }\n        float _5101 = (dot(fa_mesh_fs_params[29].xyz, _4984) + fa_mesh_fs_params[29].w) - _5083.x;\n        if ((_5101 > _4948) && (_5101 < _4953))\n        {\n            occ = max(occ, (1.0 - (_4976 * _4976)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5018, 0.5 - _5017), min(_5022, 1.0 - _5022))));\n        }\n    }\n    return 1.0 - (occ * _4934);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5233 = fa_baked_keep(param);\n    if (_5233 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5259 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6529 = _5259.color;\n    float _6530 = _5259.attenuation;\n    float _6531 = _5259.shadow;\n    bool _5262 = _5259.type == 0;\n    if (_5262 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5259.direction;\n        float _5273 = fa_shadow_factor(param_5, param_6);\n        _6531 = _5273;\n        _6529 *= _5273;\n    }\n    else\n    {\n        bool _5284 = _5259.type != 0;\n        bool _5290;\n        if (_5284)\n        {\n            _5290 = _6530 > 0.0;\n        }\n        else\n        {\n            _5290 = _5284;\n        }\n        if (_5290)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5259.direction;\n            float _5309 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6531 = _5309;\n            _6529 *= _5309;\n        }\n    }\n    bool _5319 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5325;\n    if (_5319)\n    {\n        _5325 = _6530 > 0.0;\n    }\n    else\n    {\n        _5325 = _5319;\n    }\n    if (_5325)\n    {\n        float _5332;\n        if (_5262)\n        {\n            _5332 = 1000000000.0;\n        }\n        else\n        {\n            _5332 = _5259._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5259.direction;\n        float param_18 = _5332;\n        float _5350 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6531 *= _5350;\n        _6529 *= _5350;\n    }\n    float _5363 = _6530;\n    float _5364 = _5363 * _5233;\n    _6530 = _5364;\n    vec3 _5368 = _6529;\n    vec3 _5369 = _5368 * _5233;\n    _6529 = _5369;\n    return LightSample(_5259.direction, _5369, _5364, _6531, _5259._distance, _5259.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5380 = n < 0;\n    bool _5387;\n    if (!_5380)\n    {\n        _5387 = n >= fa_light_count();\n    }\n    else\n    {\n        _5387 = _5380;\n    }\n    if (_5387)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5402 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5402;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4278 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4286 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4289 = int(_4278);\n    int _4292 = int(_4286);\n    float _4302 = _4286 - float(_4292);\n    int _4357 = (_4289 * 9) + _4292;\n    int _4377 = ((_4289 + 1) * 9) + _4292;\n    return mix(mix(_4353[_4357], _4353[_4357 + 1], _4302), mix(_4353[_4377], _4353[_4377 + 1], _4302), _4278 - float(_4289));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6395 = false;\n    float _6396 = 1.0;\n    float _6397 = 1.0;\n    float _6398 = 1.0;\n    float _6399 = 0.0;\n    float _6400 = 0.0;\n    float _6401 = 0.0;\n    float _6402 = 0.0;\n    float _6404 = 1.0;\n    bool _6405 = false;\n    vec3 _6406 = vec3(0.0);\n    float _6407 = 1.0;\n    float _6408 = 1.0;\n    float _6409 = 1.0;\n    float _6410 = 0.0;\n    float _6411 = 0.0;\n    vec3 _6412 = vec3(1.0, 0.0, 0.0);\n    vec3 _6413 = vec3(0.0, 0.0, 1.0);\n    float _6414 = 1.0;\n    float _6415 = 1.0;\n    float _4428 = clamp(s.specular, 0.0, 1.0);\n    float _4432 = clamp(s.ior, 1.0, 3.0);\n    bool _4437 = (_4428 != 1.0) || (_4432 != 1.5);\n    bool _4446;\n    if (!_4437)\n    {\n        _4446 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4446 = _4437;\n    }\n    if (_4446)\n    {\n        float _4454 = (_4432 - 1.0) / (_4432 + 1.0);\n        f0 = mix(min(vec3(_4454 * _4454) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4428, s.albedo, vec3(metallic));\n        _6396 = mix(_4428, 1.0, metallic);\n        _6395 = true;\n    }\n    float _4481 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4481 > 0.0)\n    {\n        float _4489 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6399 = _4481;\n        _6400 = _4489;\n        float _4496 = _4489 * _4489;\n        _6401 = _4496;\n        _6402 = _4496 * _4496;\n        float _4508 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6404 = _4508;\n        _6397 = 1.0 - (_4481 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4508, 0.0, 1.0), 5.0))));\n        _6395 = true;\n    }\n    vec3 _4527 = max(s.sheen_color, vec3(0.0));\n    float _4536 = max(_4527.x, max(_4527.y, _4527.z));\n    if (_4536 > 0.0)\n    {\n        float _4544 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6405 = true;\n        _6406 = _4527;\n        _6407 = _4544;\n        _6408 = _4544 * _4544;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4544;\n        float _4561 = fa_sheen_albedo(param, param_1);\n        _6410 = _4561;\n        _6409 = 1.0 - min(_4536 * _4561, 1.0);\n        _6395 = true;\n    }\n    _6398 = _6397 * _6409;\n    float _4580 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4580 != 0.0)\n    {\n        vec3 _4595 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4595;\n        if (dot(_4595, _4595) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4607 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4607.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4607.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4607.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4611 = t;\n        vec3 _4612 = normalize(_4611);\n        t = _4612;\n        vec3 _4637 = normalize((_4612 * cos(s.anisotropy_rotation)) + ((cross(n, _4612) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6412 = _4637;\n        _6413 = cross(n, _4637);\n        float _4647 = roughness * roughness;\n        float _4653 = mix(_4647, 1.0, _4580 * _4580);\n        bool _4655 = _4580 > 0.0;\n        _6414 = _4655 ? _4653 : _4647;\n        _6415 = _4655 ? _4647 : _4653;\n        _6411 = _4580;\n        _6395 = true;\n    }\n    return FaLayers(_6395, _6396, _6397, _6398, _6399, _6400, _6401, _6402, i.world_normal, _6404, _6405, _6406, _6407, _6408, _6409, _6410, _6411, _6412, _6413, _6414, _6415);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4210 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4213 = _4210.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4213 * _4213, exp2((-9.27999973297119140625) * ndv)) * _4213) + _4210.y)) + _4210.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3646 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3649 = _3646.x;\n    float _3651 = _3646.z;\n    vec2 e = vec2(_3649, _3651);\n    if (_3646.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3651)) * ((_3649 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3649)) * ((_3651 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3698;\n    if (lv == 0)\n    {\n        _3698 = 0.0;\n    }\n    else\n    {\n        _3698 = res + 2.0;\n    }\n    float _3708;\n    if (lv == 0)\n    {\n        _3708 = 0.0;\n    }\n    else\n    {\n        _3708 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3698, _3708)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3754;\n    if (res > 64.5)\n    {\n        _3754 = 5.0;\n    }\n    else\n    {\n        _3754 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3769 = clamp(rough, 0.0, 1.0) * (_3754 - 1.0);\n    int _3776 = int(min(floor(_3769), _3754 - 2.0));\n    float _3781 = _3769 - float(_3776);\n    vec3 param = d;\n    vec2 _3785 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3776;\n    vec2 param_4 = _3785;\n    vec3 _3795 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3781 < 0.00200000009499490261077880859375)\n    {\n        return _3795;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3776 + 1;\n    vec2 param_8 = _3785;\n    return mix(_3795, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3781));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3832 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3839 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3846 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3852 = dot(bx.xyz, d);\n    float _3856 = dot(by.xyz, d);\n    float _3860 = dot(bz.xyz, d);\n    float _3866;\n    if (_3852 > 9.9999999747524270787835121154785e-07)\n    {\n        _3866 = (1.0 - _3832) / _3852;\n    }\n    else\n    {\n        float _3880;\n        if (_3852 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3880 = ((-1.0) - _3832) / _3852;\n        }\n        else\n        {\n            _3880 = 1000000015047466219876688855040.0;\n        }\n        _3866 = _3880;\n    }\n    float tx = _3866;\n    float _3897;\n    if (_3856 > 9.9999999747524270787835121154785e-07)\n    {\n        _3897 = (1.0 - _3839) / _3856;\n    }\n    else\n    {\n        float _3910;\n        if (_3856 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3910 = ((-1.0) - _3839) / _3856;\n        }\n        else\n        {\n            _3910 = 1000000015047466219876688855040.0;\n        }\n        _3897 = _3910;\n    }\n    float ty = _3897;\n    float _3926;\n    if (_3860 > 9.9999999747524270787835121154785e-07)\n    {\n        _3926 = (1.0 - _3846) / _3860;\n    }\n    else\n    {\n        float _3939;\n        if (_3860 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3939 = ((-1.0) - _3846) / _3860;\n        }\n        else\n        {\n            _3939 = 1000000015047466219876688855040.0;\n        }\n        _3926 = _3939;\n    }\n    float _3951 = tx;\n    float _3954 = (_3951 > 0.0) ? _3951 : 1000000015047466219876688855040.0;\n    tx = _3954;\n    float _3955 = ty;\n    float _3958 = (_3955 > 0.0) ? _3955 : 1000000015047466219876688855040.0;\n    ty = _3958;\n    float _3968 = min(_3954, min(_3958, (_3926 > 0.0) ? _3926 : 1000000015047466219876688855040.0));\n    if (_3968 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3984 = (fa_world_pos + (d * _3968)) - posw.xyz;\n    vec3 _3989;\n    if (dot(_3984, _3984) > 1.0000000133514319600180897396058e-10)\n    {\n        _3989 = normalize(_3984);\n    }\n    else\n    {\n        _3989 = d;\n    }\n    return _3989;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4035 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4035 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4065 = rough * rough;\n            float _4096 = 0.60000002384185791015625 * _4065;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4065)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4096, 0.0500000007450580596923828125 + _4096, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4065 * 0.60000002384185791015625));\n        }\n        outc = base * _4035;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4155 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4155 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4187 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4187 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4688;\n        if (L.aniso >= 0.0)\n        {\n            _4688 = L.b;\n        }\n        else\n        {\n            _4688 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4688, v), _4688), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4724 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4724.x) + (vec3(L.f90) * _4724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4782 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4782.x) + _4782.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4252 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4252.x) + vec3(_4252.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4821 = clamp(s.metallic, 0.0, 1.0);\n    float _4825 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4832 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4821));\n    vec3 f0 = _4832;\n    vec3 _4836 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4836;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4821;\n    float param_5 = _4825;\n    vec3 param_6 = _4832;\n    FaLayers _4853 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4853.on)\n    {\n        FaLayers param_7 = _4853;\n        vec3 param_8 = _4836;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4825;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4836;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4825;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5472 = fa_light_unshadowed(param, param_1);\n        float _5480 = dot(_5472.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5480 > bestPower)\n        {\n            bestPower = _5480;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5509 = fa_light(param_2, param_3);\n        float _5517;\n        if (dot(s.normal, _5509.direction) > 0.5)\n        {\n            _5517 = 1.0;\n        }\n        else\n        {\n            _5517 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5509.color) * _5517);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3089 = int(fa_shadows[25].x + 0.5);\n    float _3099 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3104 = _3089 > 0;\n    bool _3113;\n    if (_3104)\n    {\n        int param = _3089 - 1;\n        _3113 = _3099 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3113 = _3104;\n    }\n    if (_3113)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3119 = _3089 > 1;\n        bool _3126;\n        if (_3119)\n        {\n            _3126 = _3099 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3126 = _3119;\n        }\n        if (_3126)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3132 = _3089 > 2;\n        bool _3139;\n        if (_3132)\n        {\n            _3139 = _3099 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3139 = _3132;\n        }\n        if (_3139)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3145 = _3089 > 3;\n        bool _3152;\n        if (_3145)\n        {\n            _3152 = _3099 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3152 = _3145;\n        }\n        if (_3152)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _6249 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6249 = -_6249;\n    }\n    vec3 _5919 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6249, fa_world_tangent, fa_uv, fa_vertex_color, _5919, gl_FrontFacing);\n    Surface _5927 = fa_standard_surface(param_1);\n    vec3 _6280 = _5927.albedo;\n    float _6281 = _5927.alpha;\n    vec3 _6282 = _5927.normal;\n    float _6283 = _5927.metallic;\n    float _6284 = _5927.roughness;\n    float _6285 = _5927.occlusion;\n    vec3 _6286 = _5927.emission;\n    float _6287 = _5927.clearcoat;\n    float _6288 = _5927.clearcoat_roughness;\n    vec3 _6289 = _5927.sheen_color;\n    float _6290 = _5927.sheen_roughness;\n    float _6291 = _5927.anisotropy;\n    float _6292 = _5927.anisotropy_rotation;\n    float _6293 = _5927.specular;\n    float _6294 = _5927.ior;\n    vec3 _6295 = _5927.specular_color;\n    float _6296 = _5927.transmission;\n    float _6297 = _5927.thickness;\n    vec3 _6298 = _5927.attenuation_color;\n    float _6299 = _5927.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6249, fa_world_tangent, fa_uv, fa_vertex_color, _5919, gl_FrontFacing);\n    Surface param_3 = _5927;\n    surface(param_2, param_3);\n    _6280 = param_3.albedo;\n    _6281 = param_3.alpha;\n    _6282 = param_3.normal;\n    _6283 = param_3.metallic;\n    _6284 = param_3.roughness;\n    _6285 = param_3.occlusion;\n    _6286 = param_3.emission;\n    _6287 = param_3.clearcoat;\n    _6288 = param_3.clearcoat_roughness;\n    _6289 = param_3.sheen_color;\n    _6290 = param_3.sheen_roughness;\n    _6291 = param_3.anisotropy;\n    _6292 = param_3.anisotropy_rotation;\n    _6293 = param_3.specular;\n    _6294 = param_3.ior;\n    _6295 = param_3.specular_color;\n    _6296 = param_3.transmission;\n    _6297 = param_3.thickness;\n    _6298 = param_3.attenuation_color;\n    _6299 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6249;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6280 = param_6;\n    _6282 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6280;\n    }\n    else\n    {\n        vec3 _5966 = _6282;\n        vec3 _5967 = normalize(_5966);\n        _6282 = _5967;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6249, fa_world_tangent, fa_uv, fa_vertex_color, _5919, gl_FrontFacing);\n        Surface param_9 = Surface(_6280, _6281, _5967, _6283, _6284, _6285, _6286, _6287, _6288, _6289, _6290, _6291, _6292, _6293, _6294, _6295, _6296, _6297, _6298, _6299);\n        vec3 _5978 = lighting(param_8, param_9);\n        result = _5978;\n    }\n    vec3 _5982 = result;\n    vec3 _5983 = _5982 + _6286;\n    result = _5983;\n    vec3 param_10 = _5983;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5992 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5999;\n    if (!_5992)\n    {\n        _5999 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5999 = _5992;\n    }\n    if (_5999)\n    {\n        vec3 _6008 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6014 = dot(_6008, fa_mesh_fs_params[9].xyz);\n        bool _6018 = fa_mesh_fs_params[9].w > 0.5;\n        float _6019;\n        if (_6018)\n        {\n            _6019 = _6014;\n        }\n        else\n        {\n            _6019 = length(_6008);\n        }\n        float _6031 = _6019 - fa_mesh_fs_params[8].x;\n        if (_6031 > 0.0)\n        {\n            float _6040 = fa_mesh_fs_params[7].w * _6031;\n            float tau = _6040 * _6040;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6056;\n                if (_6018)\n                {\n                    _6056 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6014);\n                }\n                else\n                {\n                    _6056 = fa_mesh_fs_params[0].y;\n                }\n                float _6077 = mix(_6056, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6019, 0.0, 1.0));\n                float _6081 = fa_world_pos.y - _6077;\n                float _6086 = _6077 - fa_mesh_fs_params[8].z;\n                float _6091 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6094 = _6086 <= 0.0;\n                bool _6095 = !_6094;\n                bool _6101;\n                if (_6095)\n                {\n                    _6101 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6101 = _6094;\n                }\n                float _6102;\n                if (_6101)\n                {\n                    _6102 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6102 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6086, 80.0));\n                }\n                bool _6129;\n                if (_6095)\n                {\n                    _6129 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6129 = _6094;\n                }\n                float _6130;\n                if (_6129)\n                {\n                    _6130 = fa_mesh_fs_params[8].y * _6086;\n                }\n                else\n                {\n                    _6130 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6086, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6155 = _6091 <= 0.0;\n                bool _6162;\n                if (!_6155)\n                {\n                    _6162 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6162 = _6155;\n                }\n                float _6163;\n                if (_6162)\n                {\n                    _6163 = fa_mesh_fs_params[8].y * _6091;\n                }\n                else\n                {\n                    _6163 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6091, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6190;\n                if (abs(_6081) < 0.001000000047497451305389404296875)\n                {\n                    _6190 = _6102;\n                }\n                else\n                {\n                    _6190 = (_6163 - _6130) / _6081;\n                }\n                tau += (_6031 * max(_6190, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6281);\n}\n\n",
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
            "inst_name": "_477",
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
            "inst_name": "_2130",
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
            "inst_name": "_5523",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4353[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1406 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1413;\n    if (!_1406)\n    {\n        _1413 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1413 = _1406;\n    }\n    bool _1421;\n    if (!_1413)\n    {\n        _1421 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1421 = _1413;\n    }\n    bool _1428;\n    if (!_1421)\n    {\n        _1428 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1428 = _1421;\n    }\n    bool _1435;\n    if (!_1428)\n    {\n        _1435 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1435 = _1428;\n    }\n    if (_1435)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1445 = vec4(world_pos, 1.0);\n    float _1451 = dot(fa_mesh_fs_params[16], _1445);\n    if (!(_1451 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1473 = vec2(dot(fa_mesh_fs_params[14], _1445), dot(fa_mesh_fs_params[15], _1445)) / vec2(_1451);\n    int _1477 = int(fa_mesh_fs_params[18].x);\n    int _1481 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1481) + clamp(int(floor(((_1473.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1481 - 1)) * _1477)) + clamp(int(floor(((_1473.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1477 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1557 = fa_cluster_texel(param);\n    return ivec2(int(_1557.x), int(_1557.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _5178 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _5181 = fwidth(_5178);\n    bool _5184 = fa_mesh_fs_params[25].y > 0.5;\n    bool _5191;\n    if (!_5184)\n    {\n        _5191 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _5191 = _5184;\n    }\n    if (_5191)\n    {\n        fa_rt_slope = min(1.5 * _5181, 0.100000001490116119384765625 * _5178);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5207 = fa_cluster_lookup(param);\n    fa_cl_slot = _5207.x;\n    fa_cl_local = _5207.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5584 = fa_linear_to_srgb(param);\n        c = _5584;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5592 = fa_srgb_to_linear(param_1);\n            c = _5592;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _358;\n    if (i.front_facing)\n    {\n        _358 = i.world_normal;\n    }\n    else\n    {\n        _358 = -i.world_normal;\n    }\n    vec3 _382 = normalize(i.world_tangent.xyz - (_358 * dot(_358, i.world_tangent.xyz)));\n    vec3 _410 = normalize(((_382 * m.x) + ((cross(_358, _382) * i.world_tangent.w) * m.y)) + (_358 * m.z));\n    vec3 _413;\n    if (i.front_facing)\n    {\n        _413 = _410;\n    }\n    else\n    {\n        _413 = -_410;\n    }\n    return _413;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5624 = fa_tex_fix(param_2, param_3);\n    vec4 _6792 = base_t;\n    _6792.x = _5624.x;\n    _6792.y = _5624.y;\n    _6792.z = _5624.z;\n    base_t = _6792;\n    vec4 _5638 = (_6792 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6577 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5672 = fa_tex_fix(param_6, param_7);\n        vec3 _5675 = (_5672 * 2.0) - vec3(1.0);\n        vec2 _5680 = _5675.xy * fa_mesh_fs_params[6].x;\n        vec3 _6800 = _5675;\n        _6800.x = _5680.x;\n        _6800.y = _5680.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6800;\n        _6577 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5710 = fa_tex_fix(param_12, param_13);\n    vec4 _6803 = mrt;\n    _6803.x = _5710.x;\n    _6803.y = _5710.y;\n    _6803.z = _5710.z;\n    mrt = _6803;\n    vec4 _5740 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5740.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5751 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5783 = fa_tex_fix(param_20, param_21);\n    float _6582 = fa_mesh_fs_params[20].x;\n    float _6583 = fa_mesh_fs_params[20].y;\n    float _6586 = fa_mesh_fs_params[20].z;\n    float _6585 = fa_mesh_fs_params[21].w;\n    float _6588 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6582 *= _5751.y;\n            _6583 *= _5751.z;\n            _6585 *= _5740.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6586 *= mrt.x;\n            _6588 *= mrt.w;\n        }\n    }\n    return Surface(_5638.xyz, _5638.w, _6577, clamp(fa_mesh_fs_params[5].x * _5710.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5710.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5751.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5783), _6582, _6583, fa_mesh_fs_params[21].xyz, _6585, _6586, fa_mesh_fs_params[20].w, _6588, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1637 = rect.zw - rect.xy;\n    vec2 _1641 = _1637 * atlas;\n    vec2 _1645 = ddx * _1641;\n    vec2 _1649 = ddy * _1641;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1637), clamp(0.5 * log2(max(max(dot(_1645, _1645), dot(_1649, _1649)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1682 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1689;\n    if (!_1682)\n    {\n        _1689 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1689 = _1682;\n    }\n    if (_1689)\n    {\n        return;\n    }\n    vec3 _1695 = dFdx(world_pos);\n    vec3 _1698 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1702 = fa_cluster_texel(param);\n    int _1706 = int(_1702.w);\n    if (_1706 < 1)\n    {\n        return;\n    }\n    int _1716 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1716;\n    vec4 _1720 = fa_light_texel(param_1);\n    vec2 _1723 = _1720.yz;\n    int _1727 = int(_1720.w);\n    int param_2 = _1716 + 1;\n    vec4 _1732 = fa_light_texel(param_2);\n    float _1733 = _1732.x;\n    int _1739 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1743 = int(_1702.z);\n    vec3 _2008;\n    for (int k = 0; k < _1706; k++)\n    {\n        int _1756 = _1743 + k;\n        int param_3 = _1727 + (_1756 >> 2);\n        int _1773 = (_1716 + 2) + (int(fa_light_texel(param_3)[_1756 & 3]) * 7);\n        int param_4 = _1773 + 6;\n        vec4 _1778 = fa_light_texel(param_4);\n        if (((int(_1778.w + 0.5) >> _1739) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1773;\n        vec4 _1793 = fa_light_texel(param_5);\n        int param_6 = _1773 + 1;\n        vec4 _1798 = fa_light_texel(param_6);\n        int param_7 = _1773 + 2;\n        vec4 _1803 = fa_light_texel(param_7);\n        vec3 _1806 = _1793.xyz;\n        float _1811 = dot(_1806, world_pos) + _1793.w;\n        vec3 _1813 = _1798.xyz;\n        float _1818 = dot(_1813, world_pos) + _1798.w;\n        vec3 _1820 = _1803.xyz;\n        float _1825 = dot(_1820, world_pos) + _1803.w;\n        bool _1830 = abs(_1811) > 0.5;\n        bool _1838;\n        if (!_1830)\n        {\n            _1838 = abs(_1818) > 0.5;\n        }\n        else\n        {\n            _1838 = _1830;\n        }\n        bool _1846;\n        if (!_1838)\n        {\n            _1846 = abs(_1825) > 0.5;\n        }\n        else\n        {\n            _1846 = _1838;\n        }\n        if (_1846)\n        {\n            continue;\n        }\n        float _1861 = clamp(dot(geo_normal, normalize(_1820)) * _1778.z, 0.0, 1.0);\n        if (_1861 <= 0.0)\n        {\n            continue;\n        }\n        float _1881 = (clamp((0.5 - abs(_1825)) * 10.0, 0.0, 1.0) * _1861) * _1778.x;\n        vec2 _1889 = vec2(_1811 + 0.5, 0.5 - _1818);\n        vec2 _1899 = vec2(dot(_1806, _1695), dot(_1813, _1695));\n        vec2 _1909 = vec2(dot(_1806, _1698), dot(_1813, _1698));\n        int param_8 = _1773 + 5;\n        vec4 _1914 = fa_light_texel(param_8);\n        int param_9 = _1773 + 3;\n        vec4 _1919 = fa_light_texel(param_9);\n        int param_10 = _1773 + 4;\n        vec4 _1924 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1914.xyz;\n        bool _1934 = _1919.z > _1919.x;\n        if (_1934)\n        {\n            vec4 param_11 = _1919;\n            vec2 param_12 = _1889;\n            vec2 param_13 = _1723;\n            vec2 param_14 = _1899;\n            vec2 param_15 = _1909;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1733 > 0.5) && (_1733 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1960 = fa_dc_to_linear(param_16);\n                vec4 _6665 = tx;\n                _6665.x = _1960.x;\n                _6665.y = _1960.y;\n                _6665.z = _1960.z;\n                tx = _6665;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1881 * tex_a) * _1914.w, 0.0, 1.0)));\n        if (_1924.z > _1924.x)\n        {\n            vec4 param_17 = _1924;\n            vec2 param_18 = _1889;\n            vec2 param_19 = _1723;\n            vec2 param_20 = _1899;\n            vec2 param_21 = _1909;\n            vec4 _2004 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1733 > 1.5)\n            {\n                vec3 param_22 = _2004.xyz;\n                vec3 _2014 = fa_dc_to_srgb(param_22);\n                _2008 = _2014;\n            }\n            else\n            {\n                _2008 = _2004.xyz;\n            }\n            vec3 _2023 = (_2008 * 2.0) - vec3(1.0);\n            vec2 _2028 = _2023.xy * _1778.y;\n            vec3 _2050 = (normalize(_1806) * _2028.x) + (normalize(_1813) * _2028.y);\n            vec3 _2053 = normalize(normal);\n            normal = normalize(mix(_2053, normalize((_2053 * max(_2023.z, 0.0500000007450580596923828125)) + (_2050 - (_2053 * dot(_2053, _2050)))), vec3(clamp(_1881 * (_1934 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5148;\n    if (fa_lm.z > 0.5)\n    {\n        _5148 = 0.0;\n    }\n    else\n    {\n        _5148 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5159 = _5148 < 1.0;\n    bool _5165;\n    if (_5159)\n    {\n        int param = li;\n        _5165 = fa_light_baked(param);\n    }\n    else\n    {\n        _5165 = _5159;\n    }\n    return _5165 ? _5148 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _655 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _668 = (c - (ru * hx)) - p;\n        vec3 _674 = ru * (2.0 * hx);\n        float _680 = max(dot(_674, _674), 9.9999999392252902907785028219223e-09);\n        float _684 = dot(_668, _674);\n        float t = clamp((-_684) / _680, 0.0, 1.0);\n        if (_655)\n        {\n            float _699 = dot(r, _674);\n            float _705 = _680 - (_699 * _699);\n            if (abs(_705) > (9.9999997473787516355514526367188e-06 * _680))\n            {\n                t = clamp(((dot(r, _668) * _699) - _684) / _705, 0.0, 1.0);\n            }\n        }\n        return (p + _668) + (_674 * t);\n    }\n    vec3 q = p;\n    float _737 = dot(r, axis);\n    bool _745;\n    if (_655)\n    {\n        _745 = abs(_737) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _745 = _655;\n    }\n    if (_745)\n    {\n        float _755 = dot(c - p, axis) / _737;\n        if (_755 > 0.0)\n        {\n            q = p + (r * _755);\n        }\n    }\n    vec3 _768 = q - c;\n    vec2 xy = vec2(dot(_768, ru), dot(_768, uu));\n    if (shape > 0.5)\n    {\n        float _783 = length(xy);\n        if (_783 > hx)\n        {\n            xy *= (hx / _783);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _575 = dot(d, right);\n    float _579 = dot(d, up);\n    float _590;\n    if (((_575 * _575) + (_579 * _579)) > 1.0000000133514319600180897396058e-10)\n    {\n        _590 = atan(_579, _575) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _590 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_590 - floor(_590)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _425 = abs(d);\n    float _427 = _425.x;\n    float _429 = _425.y;\n    bool _430 = _427 >= _429;\n    bool _438;\n    if (_430)\n    {\n        _438 = _427 >= _425.z;\n    }\n    else\n    {\n        _438 = _430;\n    }\n    int _439;\n    if (_438)\n    {\n        _439 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _453;\n        if (_429 >= _425.z)\n        {\n            _453 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _453 = (d.z > 0.0) ? 4 : 5;\n        }\n        _439 = _453;\n    }\n    return _439;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _821 = fa_light_base(param);\n    bool _825 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _821;\n    vec4 _829 = fa_light_texel(param_1);\n    int param_2 = _821 + 1;\n    vec4 _834 = fa_light_texel(param_2);\n    float _837 = _834.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _849 = _825 && (_837 > 2.5);\n    fa_light_is_area = _849;\n    bool _851 = _837 < 0.5;\n    vec3 l;\n    if (_851)\n    {\n        l = normalize(_829.xyz);\n        if (_825)\n        {\n            int param_3 = _821 + 6;\n            vec4 _865 = fa_light_texel(param_3);\n            if (_865.z > 0.5)\n            {\n                int param_4 = _821 + 4;\n                vec4 _875 = fa_light_texel(param_4);\n                int param_5 = _821 + 5;\n                vec4 _880 = fa_light_texel(param_5);\n                vec2 param_6 = _865.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _875.xyz) * _875.w, (-dot(world_pos, _880.xyz)) * _880.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _910 = _829.xyz;\n        vec3 _912 = _910 - world_pos;\n        vec3 to_light = _912;\n        float _915 = length(_912);\n        float reach = _915;\n        bool front = true;\n        if (_849)\n        {\n            int param_8 = _821 + 7;\n            reach = max(_915 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _821 + 4;\n            vec4 _939 = fa_light_texel(param_9);\n            int param_10 = _821 + 5;\n            vec4 _944 = fa_light_texel(param_10);\n            int param_11 = _821 + 6;\n            vec4 _949 = fa_light_texel(param_11);\n            float _950 = _949.w;\n            int param_12 = _821 + 2;\n            vec3 _957 = normalize(fa_light_texel(param_12).xyz);\n            bool _959 = _950 > 1.5;\n            bool _967;\n            if (!_959)\n            {\n                _967 = dot(_957, to_light) < 0.0;\n            }\n            else\n            {\n                _967 = _959;\n            }\n            front = _967;\n            vec3 r = vec3(0.0);\n            vec3 _976 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _980 = dot(n, n) > 0.5;\n            bool _988;\n            if (_980)\n            {\n                _988 = dot(_976, _976) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _988 = _980;\n            }\n            if (_988)\n            {\n                r = reflect(-normalize(_976), normalize(n));\n            }\n            vec3 param_13 = _910;\n            vec3 param_14 = _957;\n            vec3 param_15 = _939.xyz;\n            vec3 param_16 = _944.xyz;\n            float param_17 = _939.w;\n            float param_18 = _944.w;\n            float param_19 = _950;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1024 = length(to_light);\n        dist = _1024;\n        l = to_light / vec3(max(_1024, 9.9999997473787516355514526367188e-05));\n        float _1038 = reach / max(_829.w, 0.001000000047497451305389404296875);\n        float _1044 = clamp(1.0 - (_1038 * _1038), 0.0, 1.0);\n        float _1046;\n        if (front)\n        {\n            _1046 = _1044 * _1044;\n        }\n        else\n        {\n            _1046 = 0.0;\n        }\n        atten = _1046;\n        bool _1057 = _837 < 2.5;\n        if ((_837 > 1.5) && _1057)\n        {\n            int param_22 = _821 + 2;\n            vec4 _1065 = fa_light_texel(param_22);\n            float _1075 = _1065.w;\n            int param_23 = _821 + 3;\n            vec4 _1080 = fa_light_texel(param_23);\n            float _1081 = _1080.x;\n            float cos_inner = _1081;\n            if (_1081 > 1.5)\n            {\n                cos_inner = mix(_1075, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1075, cos_inner, dot(-l, normalize(_1065.xyz)));\n        }\n        if (_825 && (_837 < 1.5))\n        {\n            int param_24 = _821 + 6;\n            vec4 _1105 = fa_light_texel(param_24);\n            if (_1105.z > 0.5)\n            {\n                vec3 _1113 = -to_light;\n                int param_25 = _821 + 4;\n                int param_26 = _821 + 5;\n                vec3 _1127 = fa_light_texel(param_25).xyz;\n                vec3 _1131 = fa_light_texel(param_26).xyz;\n                vec3 _1140 = vec3(dot(_1113, _1127), dot(_1113, _1131), dot(_1113, cross(_1127, _1131)));\n                vec3 param_27 = _1140;\n                int _1144 = fa_cube_face(param_27);\n                int param_28 = _1144;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1171 = vec2(dot(_1140, cross(param_29, param_30)), dot(_1140, param_30)) / vec2(max(dot(_1140, param_29), 9.9999997473787516355514526367188e-05));\n                int _1175 = _1144 / 3;\n                vec2 param_31 = _1105.xy + (vec2(float(_1144 - (_1175 * 3)), float(_1175)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1171.x), 0.5 - (0.5 * _1171.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _821 + 7;\n            vec4 _1205 = fa_light_texel(param_33);\n            if (_1205.z > 0.5)\n            {\n                int param_34 = _821 + 2;\n                int param_35 = _821 + 4;\n                int param_36 = _821 + 5;\n                vec2 param_37 = _1205.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_825 && _1057)\n            {\n                int param_42 = _821 + 6;\n                vec4 _1252 = fa_light_texel(param_42);\n                int param_43 = _821 + 7;\n                vec4 _1257 = fa_light_texel(param_43);\n                bool _1260 = _1252.z > 0.5;\n                bool _1267;\n                if (!_1260)\n                {\n                    _1267 = _1257.z > 0.5;\n                }\n                else\n                {\n                    _1267 = _1260;\n                }\n                if (_1267)\n                {\n                    int param_44 = _821 + 2;\n                    vec4 _1274 = fa_light_texel(param_44);\n                    vec3 _1278 = normalize(_1274.xyz);\n                    int param_45 = _821 + 4;\n                    vec4 _1283 = fa_light_texel(param_45);\n                    int param_46 = _821 + 5;\n                    vec4 _1288 = fa_light_texel(param_46);\n                    if (_1260)\n                    {\n                        vec3 _1296 = -to_light;\n                        float _1303 = _1274.w;\n                        float _1319 = 0.5 / max(dot(_1296, _1278) * (sqrt(max(1.0 - (_1303 * _1303), 0.0)) / max(_1303, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1252.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1296, _1283.xyz) * _1319), 0.5 - (dot(_1296, _1288.xyz) * _1319));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1257.z > 0.5)\n                    {\n                        vec2 param_49 = _1257.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1278;\n                        vec3 param_52 = _1283.xyz;\n                        vec3 param_53 = _1288.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6383 = _834.xyz * atten;\n    if (_825)\n    {\n        _6383 *= fa_light_tint;\n    }\n    int _1388;\n    if (_851)\n    {\n        _1388 = 0;\n    }\n    else\n    {\n        _1388 = ((_837 > 1.5) && (_837 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6383, atten, 1.0, dist, _1388);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5406 = n < 0;\n    bool _5413;\n    if (!_5406)\n    {\n        _5413 = n >= fa_light_count();\n    }\n    else\n    {\n        _5413 = _5406;\n    }\n    if (_5413)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5421 = fa_cl_light(param);\n    int param_1 = _5421;\n    float _5425 = fa_baked_keep(param_1);\n    if (_5425 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5421;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5441 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5441.direction, _5441.color * _5425, _5441.attenuation * _5425, _5441.shadow, _5441._distance, _5441.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2177 = fa_shadow_depth(param, param_1);\n    float _2181;\n    if (conv.x < 0.5)\n    {\n        _2181 = _2177;\n    }\n    else\n    {\n        _2181 = (conv.y * conv.z) / (conv.z - (_2177 * (conv.z - conv.y)));\n    }\n    return _2181;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2227 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2233 = vec2(cos(_2227), sin(_2227));\n    vec2 dir = _2233;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2242;\n        if (k < 0.0)\n        {\n            _2242 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2242 = k;\n        }\n        float _2261 = clamp((_2242 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2280 = sqrt((float(i) + 0.5) * 0.0625) * _2261;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2280));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2294 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2294 < (zr - (_2280 * plane)))\n            {\n                sum += _2294;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2322 = sum / cnt;\n        float _2332;\n        if (k < 0.0)\n        {\n            _2332 = (-k) / max(_2322, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2332 = k;\n        }\n        radius = clamp(((max(zr - _2322, 0.0) * unit) * _2332) / texel_m, 1.5, 16.0);\n        dir = _2233;\n    }\n    float lit = 0.0;\n    int _2358 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2358; i_1++)\n    {\n        float _2377 = sqrt((float(i_1) + 0.5) / float(_2358)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2377));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2377 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2358);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2582 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2589;\n    if (!_2582)\n    {\n        _2589 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2589 = _2582;\n    }\n    if (_2589)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2602 = fa_light_texel(param);\n    float _2603 = _2602.x;\n    if (_2603 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2612 = int(_2603 + 0.5);\n    int param_1 = _2612;\n    vec4 _2616 = fa_light_texel(param_1);\n    int param_2 = _2612 + 1;\n    vec4 _2621 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2624 = _2616.y;\n    if (_2624 > 0.0)\n    {\n        float _2641 = 1.0 - smoothstep(0.75 * _2624, _2624, length(world - fa_shadows[27].xyz));\n        fade = _2641;\n        if (_2641 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2616.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2665 = (_2612 + 2) + (face * 6);\n    int param_4 = _2665;\n    int param_5 = _2665 + 1;\n    int param_6 = _2665 + 3;\n    vec4 _2679 = fa_light_texel(param_6);\n    int param_7 = _2665 + 4;\n    vec4 _2684 = fa_light_texel(param_7);\n    int param_8 = _2665 + 5;\n    vec4 _2689 = fa_light_texel(param_8);\n    float _2701 = _2689.x * max(dot(_2679, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2706 = clamp(dot(n, l), 0.0, 1.0);\n    float _2729 = clamp(dot(n, _2679.xyz), -1.0, 1.0);\n    float _2748 = min(sqrt(1.0 - (_2729 * _2729)) / max(abs(dot(n, world - lpos)) / max(dot(_2679, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2751 = _2621.y;\n    float _2753;\n    if (_2751 > 0.0)\n    {\n        _2753 = _2751;\n    }\n    else\n    {\n        _2753 = 1.5 * _2701;\n    }\n    vec4 _2773 = vec4(world + (n * (_2753 * sqrt(1.0 - (_2706 * _2706)))), 1.0);\n    float _2777 = dot(_2679, _2773);\n    float _2780 = _2689.y;\n    if (_2777 < _2780)\n    {\n        return 1.0;\n    }\n    vec2 _2795 = vec2(dot(fa_light_texel(param_4), _2773), dot(fa_light_texel(param_5), _2773)) / vec2(_2777);\n    float _2797 = _2795.x;\n    bool _2800 = _2797 < _2684.x;\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2797 > _2684.z;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2795.y < _2684.y;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    bool _2827;\n    if (!_2818)\n    {\n        _2827 = _2795.y > _2684.w;\n    }\n    else\n    {\n        _2827 = _2818;\n    }\n    if (_2827)\n    {\n        return 1.0;\n    }\n    float _2833 = _2621.x;\n    float _2835;\n    if (_2833 > 0.0)\n    {\n        _2835 = _2833;\n    }\n    else\n    {\n        _2835 = 1.5 * _2701;\n    }\n    vec2 param_9 = _2795;\n    vec4 param_10 = _2684;\n    float param_11 = _2777 - (_2835 * (1.0 + (0.5 * _2748)));\n    float param_12 = _2701;\n    float param_13 = 1.0;\n    float param_14 = _2689.z * 0.25;\n    float param_15 = (_2701 * min(_2748, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2780, _2689.z);\n    int param_17 = int(_2616.z + 0.5);\n    float param_18 = _2616.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3342 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3348;\n    if (_3342)\n    {\n        _3348 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3348 = _3342;\n    }\n    bool _3354;\n    if (_3348)\n    {\n        _3354 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3354 = _3348;\n    }\n    if (_3354)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3366 = fa_light_texel(param);\n        float _3367 = _3366.z;\n        if (_3367 > 0.5)\n        {\n            float _3380 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3386 = ((0.00200000009499490261077880859375 * _3380) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3392 = vec4(world, 1.0);\n            float _3397 = dot(fa_mesh_fs_params[28], _3392);\n            if (_3397 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3414 = vec2(dot(fa_mesh_fs_params[26], _3392), dot(fa_mesh_fs_params[27], _3392)) / vec2(_3397);\n                float _3419 = (_3414.x * 0.5) + 0.5;\n                float _3423;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3423 = (_3414.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3423 = 0.5 - (_3414.y * 0.5);\n                }\n                bool _3439 = _3419 >= 0.0;\n                bool _3445;\n                if (_3439)\n                {\n                    _3445 = _3419 < 1.0;\n                }\n                else\n                {\n                    _3445 = _3439;\n                }\n                bool _3451;\n                if (_3445)\n                {\n                    _3451 = _3423 >= 0.0;\n                }\n                else\n                {\n                    _3451 = _3445;\n                }\n                bool _3457;\n                if (_3451)\n                {\n                    _3457 = _3423 < 1.0;\n                }\n                else\n                {\n                    _3457 = _3451;\n                }\n                if (_3457)\n                {\n                    ivec2 _3474 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3475 = clamp(ivec2(vec2(_3419, _3423) * fa_mesh_fs_params[24].zw), ivec2(0), _3474);\n                    float _3479;\n                    if (_3367 < 1.5)\n                    {\n                        _3479 = 1.0;\n                    }\n                    else\n                    {\n                        _3479 = (_3367 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3501;\n                    int _3507;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3501 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3507 = k - 1;\n                            }\n                            else\n                            {\n                                _3507 = k;\n                            }\n                            _3501 = _3507;\n                        }\n                        vec4 _3536 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3475 + ivec2((_3501 % 3) - 1, (_3501 / 3) - 1), ivec2(0), _3474), 0);\n                        bool _3539 = _3536.w > 0.5;\n                        bool _3549;\n                        if (_3539)\n                        {\n                            _3549 = abs(_3380 - _3536.x) <= _3386;\n                        }\n                        else\n                        {\n                            _3549 = _3539;\n                        }\n                        if (_3549)\n                        {\n                            best = min(best, mod(floor(_3536.z / _3479), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3576;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3576 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3576 = best;\n                        }\n                        return _3576;\n                    }\n                }\n            }\n            float _3599;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3599 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3599 = 1.0;\n            }\n            return _3599;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2120;\n    if (i == 0)\n    {\n        _2120 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2136;\n        if (i == 1)\n        {\n            _2136 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2144;\n            if (i == 2)\n            {\n                _2144 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2144 = fa_shadows[24].w;\n            }\n            _2136 = _2144;\n        }\n        _2120 = _2136;\n    }\n    return _2120;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2423 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2428 = clamp(dot(n, l), 0.0, 1.0);\n    float _2434 = sqrt(1.0 - (_2428 * _2428));\n    float _2442 = min(_2434 / max(_2428, 0.20000000298023223876953125), 4.0);\n    float _2447;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2447 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2447 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2472 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2447 * _2434)), 1.0);\n    float _2479 = _2472.x;\n    bool _2482 = _2479 < fa_shadows[ci * 1 + 16].x;\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2479 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2472.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2509;\n    if (!_2500)\n    {\n        _2509 = _2472.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2509 = _2500;\n    }\n    bool _2516;\n    if (!_2509)\n    {\n        _2516 = _2472.z > 1.0;\n    }\n    else\n    {\n        _2516 = _2509;\n    }\n    if (_2516)\n    {\n        return -1.0;\n    }\n    float _2524;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2524 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2524 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2472.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2472.z - ((_2524 * (1.0 + (0.5 * _2442))) / _2423);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2423;\n    float param_5 = _2423 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2442, 3.0)) * 0.5) / _2423;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2902 = int(fa_shadows[25].x + 0.5);\n    if (_2902 < 1)\n    {\n        return 1.0;\n    }\n    float _2917 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2902 - 1;\n    if (_2917 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2929 = _2902 > 1;\n    bool _2936;\n    if (_2929)\n    {\n        _2936 = _2917 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2936 = _2929;\n    }\n    if (_2936)\n    {\n        ci = 1;\n    }\n    bool _2940 = _2902 > 2;\n    bool _2947;\n    if (_2940)\n    {\n        _2947 = _2917 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2947 = _2940;\n    }\n    if (_2947)\n    {\n        ci = 2;\n    }\n    bool _2951 = _2902 > 3;\n    bool _2958;\n    if (_2951)\n    {\n        _2958 = _2917 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2958 = _2951;\n    }\n    if (_2958)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2969 = min(_2902, 4);\n    float _3010;\n    for (int c = ci; c < _2969; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2989 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2989;\n            break;\n        }\n        if (_2989 < 0.0)\n        {\n            continue;\n        }\n        s = _2989;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3010 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3010 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3029 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3010, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2917 - (fa_shadow_split_at(param_7) - _3029)) / _3029, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3061;\n        if ((ci + 1) < _2902)\n        {\n            _3061 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3061 = 1.0;\n        }\n        s = mix(s, _3061, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3166 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3172;\n    if (_3166)\n    {\n        _3172 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3172 = _3166;\n    }\n    if (_3172)\n    {\n        float _3186 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3194 = vec4(fa_world_pos, 1.0);\n        float _3200 = dot(fa_mesh_fs_params[28], _3194);\n        if (_3200 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3219 = vec2(dot(fa_mesh_fs_params[26], _3194), dot(fa_mesh_fs_params[27], _3194)) / vec2(_3200);\n            float _3224 = (_3219.x * 0.5) + 0.5;\n            float _3228;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3228 = (_3219.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3228 = 0.5 - (_3219.y * 0.5);\n            }\n            bool _3244 = _3224 >= 0.0;\n            bool _3250;\n            if (_3244)\n            {\n                _3250 = _3224 < 1.0;\n            }\n            else\n            {\n                _3250 = _3244;\n            }\n            bool _3256;\n            if (_3250)\n            {\n                _3256 = _3228 >= 0.0;\n            }\n            else\n            {\n                _3256 = _3250;\n            }\n            bool _3262;\n            if (_3256)\n            {\n                _3262 = _3228 < 1.0;\n            }\n            else\n            {\n                _3262 = _3256;\n            }\n            if (_3262)\n            {\n                vec4 _3288 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3224, _3228) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3291 = _3288.w > 0.5;\n                bool _3307;\n                if (_3291)\n                {\n                    _3307 = abs(_3186 - _3288.x) <= (((0.00200000009499490261077880859375 * _3186) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3307 = _3291;\n                }\n                if (_3307)\n                {\n                    float _3313;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3313 = min(_3288.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3313 = _3288.y;\n                    }\n                    return _3313;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4892 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4899;\n    if (!_4892)\n    {\n        _4899 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4899 = _4892;\n    }\n    if (_4899)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4912 = fa_light_texel(param);\n    float _4913 = _4912.y;\n    float len = _4913;\n    if (_4913 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4925 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4934 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4925);\n    if (_4934 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4940 = len;\n    float _4943 = min(_4940, 0.89999997615814208984375 * dist);\n    len = _4943;\n    float _4948 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4925);\n    float _4953 = _4948 + (0.5 * _4943);\n    vec3 _4959 = world + (gn * _4948);\n    float _4961 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5022;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4976 = (float(k) + _4961) * 0.083333335816860198974609375;\n        vec3 _4984 = _4959 + (l * (_4976 * len));\n        vec4 _4990 = vec4(_4984, 1.0);\n        float _4995 = dot(fa_mesh_fs_params[28], _4990);\n        if (_4995 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5013 = vec2(dot(fa_mesh_fs_params[26], _4990), dot(fa_mesh_fs_params[27], _4990)) / vec2(_4995);\n        float _5017 = _5013.x * 0.5;\n        float _5018 = _5017 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5022 = (_5013.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5022 = 0.5 - (_5013.y * 0.5);\n        }\n        bool _5038 = _5018 < 0.0;\n        bool _5045;\n        if (!_5038)\n        {\n            _5045 = _5018 >= 1.0;\n        }\n        else\n        {\n            _5045 = _5038;\n        }\n        bool _5052;\n        if (!_5045)\n        {\n            _5052 = _5022 < 0.0;\n        }\n        else\n        {\n            _5052 = _5045;\n        }\n        bool _5059;\n        if (!_5052)\n        {\n            _5059 = _5022 >= 1.0;\n        }\n        else\n        {\n            _5059 = _5052;\n        }\n        if (_5059)\n        {\n            break;\n        }\n        vec4 _5083 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5018, _5022) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5083.w < 0.5)\n        {\n            continue;\n        }\n        float _5101 = (dot(fa_mesh_fs_params[29].xyz, _4984) + fa_mesh_fs_params[29].w) - _5083.x;\n        if ((_5101 > _4948) && (_5101 < _4953))\n        {\n            occ = max(occ, (1.0 - (_4976 * _4976)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5018, 0.5 - _5017), min(_5022, 1.0 - _5022))));\n        }\n    }\n    return 1.0 - (occ * _4934);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5233 = fa_baked_keep(param);\n    if (_5233 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5259 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6529 = _5259.color;\n    float _6530 = _5259.attenuation;\n    float _6531 = _5259.shadow;\n    bool _5262 = _5259.type == 0;\n    if (_5262 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5259.direction;\n        float _5273 = fa_shadow_factor(param_5, param_6);\n        _6531 = _5273;\n        _6529 *= _5273;\n    }\n    else\n    {\n        bool _5284 = _5259.type != 0;\n        bool _5290;\n        if (_5284)\n        {\n            _5290 = _6530 > 0.0;\n        }\n        else\n        {\n            _5290 = _5284;\n        }\n        if (_5290)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5259.direction;\n            float _5309 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6531 = _5309;\n            _6529 *= _5309;\n        }\n    }\n    bool _5319 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5325;\n    if (_5319)\n    {\n        _5325 = _6530 > 0.0;\n    }\n    else\n    {\n        _5325 = _5319;\n    }\n    if (_5325)\n    {\n        float _5332;\n        if (_5262)\n        {\n            _5332 = 1000000000.0;\n        }\n        else\n        {\n            _5332 = _5259._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5259.direction;\n        float param_18 = _5332;\n        float _5350 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6531 *= _5350;\n        _6529 *= _5350;\n    }\n    float _5363 = _6530;\n    float _5364 = _5363 * _5233;\n    _6530 = _5364;\n    vec3 _5368 = _6529;\n    vec3 _5369 = _5368 * _5233;\n    _6529 = _5369;\n    return LightSample(_5259.direction, _5369, _5364, _6531, _5259._distance, _5259.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5380 = n < 0;\n    bool _5387;\n    if (!_5380)\n    {\n        _5387 = n >= fa_light_count();\n    }\n    else\n    {\n        _5387 = _5380;\n    }\n    if (_5387)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5402 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5402;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4278 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4286 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4289 = int(_4278);\n    int _4292 = int(_4286);\n    float _4302 = _4286 - float(_4292);\n    int _4357 = (_4289 * 9) + _4292;\n    int _4377 = ((_4289 + 1) * 9) + _4292;\n    return mix(mix(_4353[_4357], _4353[_4357 + 1], _4302), mix(_4353[_4377], _4353[_4377 + 1], _4302), _4278 - float(_4289));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6395 = false;\n    float _6396 = 1.0;\n    float _6397 = 1.0;\n    float _6398 = 1.0;\n    float _6399 = 0.0;\n    float _6400 = 0.0;\n    float _6401 = 0.0;\n    float _6402 = 0.0;\n    float _6404 = 1.0;\n    bool _6405 = false;\n    vec3 _6406 = vec3(0.0);\n    float _6407 = 1.0;\n    float _6408 = 1.0;\n    float _6409 = 1.0;\n    float _6410 = 0.0;\n    float _6411 = 0.0;\n    vec3 _6412 = vec3(1.0, 0.0, 0.0);\n    vec3 _6413 = vec3(0.0, 0.0, 1.0);\n    float _6414 = 1.0;\n    float _6415 = 1.0;\n    float _4428 = clamp(s.specular, 0.0, 1.0);\n    float _4432 = clamp(s.ior, 1.0, 3.0);\n    bool _4437 = (_4428 != 1.0) || (_4432 != 1.5);\n    bool _4446;\n    if (!_4437)\n    {\n        _4446 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4446 = _4437;\n    }\n    if (_4446)\n    {\n        float _4454 = (_4432 - 1.0) / (_4432 + 1.0);\n        f0 = mix(min(vec3(_4454 * _4454) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4428, s.albedo, vec3(metallic));\n        _6396 = mix(_4428, 1.0, metallic);\n        _6395 = true;\n    }\n    float _4481 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4481 > 0.0)\n    {\n        float _4489 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6399 = _4481;\n        _6400 = _4489;\n        float _4496 = _4489 * _4489;\n        _6401 = _4496;\n        _6402 = _4496 * _4496;\n        float _4508 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6404 = _4508;\n        _6397 = 1.0 - (_4481 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4508, 0.0, 1.0), 5.0))));\n        _6395 = true;\n    }\n    vec3 _4527 = max(s.sheen_color, vec3(0.0));\n    float _4536 = max(_4527.x, max(_4527.y, _4527.z));\n    if (_4536 > 0.0)\n    {\n        float _4544 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6405 = true;\n        _6406 = _4527;\n        _6407 = _4544;\n        _6408 = _4544 * _4544;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4544;\n        float _4561 = fa_sheen_albedo(param, param_1);\n        _6410 = _4561;\n        _6409 = 1.0 - min(_4536 * _4561, 1.0);\n        _6395 = true;\n    }\n    _6398 = _6397 * _6409;\n    float _4580 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4580 != 0.0)\n    {\n        vec3 _4595 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4595;\n        if (dot(_4595, _4595) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4607 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4607.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4607.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4607.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4611 = t;\n        vec3 _4612 = normalize(_4611);\n        t = _4612;\n        vec3 _4637 = normalize((_4612 * cos(s.anisotropy_rotation)) + ((cross(n, _4612) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6412 = _4637;\n        _6413 = cross(n, _4637);\n        float _4647 = roughness * roughness;\n        float _4653 = mix(_4647, 1.0, _4580 * _4580);\n        bool _4655 = _4580 > 0.0;\n        _6414 = _4655 ? _4653 : _4647;\n        _6415 = _4655 ? _4647 : _4653;\n        _6411 = _4580;\n        _6395 = true;\n    }\n    return FaLayers(_6395, _6396, _6397, _6398, _6399, _6400, _6401, _6402, i.world_normal, _6404, _6405, _6406, _6407, _6408, _6409, _6410, _6411, _6412, _6413, _6414, _6415);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4210 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4213 = _4210.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4213 * _4213, exp2((-9.27999973297119140625) * ndv)) * _4213) + _4210.y)) + _4210.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3646 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3649 = _3646.x;\n    float _3651 = _3646.z;\n    vec2 e = vec2(_3649, _3651);\n    if (_3646.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3651)) * ((_3649 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3649)) * ((_3651 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3698;\n    if (lv == 0)\n    {\n        _3698 = 0.0;\n    }\n    else\n    {\n        _3698 = res + 2.0;\n    }\n    float _3708;\n    if (lv == 0)\n    {\n        _3708 = 0.0;\n    }\n    else\n    {\n        _3708 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3698, _3708)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3754;\n    if (res > 64.5)\n    {\n        _3754 = 5.0;\n    }\n    else\n    {\n        _3754 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3769 = clamp(rough, 0.0, 1.0) * (_3754 - 1.0);\n    int _3776 = int(min(floor(_3769), _3754 - 2.0));\n    float _3781 = _3769 - float(_3776);\n    vec3 param = d;\n    vec2 _3785 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3776;\n    vec2 param_4 = _3785;\n    vec3 _3795 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3781 < 0.00200000009499490261077880859375)\n    {\n        return _3795;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3776 + 1;\n    vec2 param_8 = _3785;\n    return mix(_3795, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3781));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3832 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3839 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3846 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3852 = dot(bx.xyz, d);\n    float _3856 = dot(by.xyz, d);\n    float _3860 = dot(bz.xyz, d);\n    float _3866;\n    if (_3852 > 9.9999999747524270787835121154785e-07)\n    {\n        _3866 = (1.0 - _3832) / _3852;\n    }\n    else\n    {\n        float _3880;\n        if (_3852 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3880 = ((-1.0) - _3832) / _3852;\n        }\n        else\n        {\n            _3880 = 1000000015047466219876688855040.0;\n        }\n        _3866 = _3880;\n    }\n    float tx = _3866;\n    float _3897;\n    if (_3856 > 9.9999999747524270787835121154785e-07)\n    {\n        _3897 = (1.0 - _3839) / _3856;\n    }\n    else\n    {\n        float _3910;\n        if (_3856 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3910 = ((-1.0) - _3839) / _3856;\n        }\n        else\n        {\n            _3910 = 1000000015047466219876688855040.0;\n        }\n        _3897 = _3910;\n    }\n    float ty = _3897;\n    float _3926;\n    if (_3860 > 9.9999999747524270787835121154785e-07)\n    {\n        _3926 = (1.0 - _3846) / _3860;\n    }\n    else\n    {\n        float _3939;\n        if (_3860 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3939 = ((-1.0) - _3846) / _3860;\n        }\n        else\n        {\n            _3939 = 1000000015047466219876688855040.0;\n        }\n        _3926 = _3939;\n    }\n    float _3951 = tx;\n    float _3954 = (_3951 > 0.0) ? _3951 : 1000000015047466219876688855040.0;\n    tx = _3954;\n    float _3955 = ty;\n    float _3958 = (_3955 > 0.0) ? _3955 : 1000000015047466219876688855040.0;\n    ty = _3958;\n    float _3968 = min(_3954, min(_3958, (_3926 > 0.0) ? _3926 : 1000000015047466219876688855040.0));\n    if (_3968 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3984 = (fa_world_pos + (d * _3968)) - posw.xyz;\n    vec3 _3989;\n    if (dot(_3984, _3984) > 1.0000000133514319600180897396058e-10)\n    {\n        _3989 = normalize(_3984);\n    }\n    else\n    {\n        _3989 = d;\n    }\n    return _3989;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4035 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4035 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4065 = rough * rough;\n            float _4096 = 0.60000002384185791015625 * _4065;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4065)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4096, 0.0500000007450580596923828125 + _4096, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4065 * 0.60000002384185791015625));\n        }\n        outc = base * _4035;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4155 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4155 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4187 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4187 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4688;\n        if (L.aniso >= 0.0)\n        {\n            _4688 = L.b;\n        }\n        else\n        {\n            _4688 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4688, v), _4688), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4724 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4724.x) + (vec3(L.f90) * _4724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4782 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4782.x) + _4782.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4252 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4252.x) + vec3(_4252.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4821 = clamp(s.metallic, 0.0, 1.0);\n    float _4825 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4832 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4821));\n    vec3 f0 = _4832;\n    vec3 _4836 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4836;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4821;\n    float param_5 = _4825;\n    vec3 param_6 = _4832;\n    FaLayers _4853 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4853.on)\n    {\n        FaLayers param_7 = _4853;\n        vec3 param_8 = _4836;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4825;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4836;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4825;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5472 = fa_light_unshadowed(param, param_1);\n        float _5480 = dot(_5472.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5480 > bestPower)\n        {\n            bestPower = _5480;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5509 = fa_light(param_2, param_3);\n        float _5517;\n        if (dot(s.normal, _5509.direction) > 0.5)\n        {\n            _5517 = 1.0;\n        }\n        else\n        {\n            _5517 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5509.color) * _5517);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3089 = int(fa_shadows[25].x + 0.5);\n    float _3099 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3104 = _3089 > 0;\n    bool _3113;\n    if (_3104)\n    {\n        int param = _3089 - 1;\n        _3113 = _3099 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3113 = _3104;\n    }\n    if (_3113)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3119 = _3089 > 1;\n        bool _3126;\n        if (_3119)\n        {\n            _3126 = _3099 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3126 = _3119;\n        }\n        if (_3126)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3132 = _3089 > 2;\n        bool _3139;\n        if (_3132)\n        {\n            _3139 = _3099 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3139 = _3132;\n        }\n        if (_3139)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3145 = _3089 > 3;\n        bool _3152;\n        if (_3145)\n        {\n            _3152 = _3099 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3152 = _3145;\n        }\n        if (_3152)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _6249 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6249 = -_6249;\n    }\n    vec3 _5919 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6249, fa_world_tangent, fa_uv, fa_vertex_color, _5919, gl_FrontFacing);\n    Surface _5927 = fa_standard_surface(param_1);\n    vec3 _6280 = _5927.albedo;\n    float _6281 = _5927.alpha;\n    vec3 _6282 = _5927.normal;\n    float _6283 = _5927.metallic;\n    float _6284 = _5927.roughness;\n    float _6285 = _5927.occlusion;\n    vec3 _6286 = _5927.emission;\n    float _6287 = _5927.clearcoat;\n    float _6288 = _5927.clearcoat_roughness;\n    vec3 _6289 = _5927.sheen_color;\n    float _6290 = _5927.sheen_roughness;\n    float _6291 = _5927.anisotropy;\n    float _6292 = _5927.anisotropy_rotation;\n    float _6293 = _5927.specular;\n    float _6294 = _5927.ior;\n    vec3 _6295 = _5927.specular_color;\n    float _6296 = _5927.transmission;\n    float _6297 = _5927.thickness;\n    vec3 _6298 = _5927.attenuation_color;\n    float _6299 = _5927.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6249, fa_world_tangent, fa_uv, fa_vertex_color, _5919, gl_FrontFacing);\n    Surface param_3 = _5927;\n    surface(param_2, param_3);\n    _6280 = param_3.albedo;\n    _6281 = param_3.alpha;\n    _6282 = param_3.normal;\n    _6283 = param_3.metallic;\n    _6284 = param_3.roughness;\n    _6285 = param_3.occlusion;\n    _6286 = param_3.emission;\n    _6287 = param_3.clearcoat;\n    _6288 = param_3.clearcoat_roughness;\n    _6289 = param_3.sheen_color;\n    _6290 = param_3.sheen_roughness;\n    _6291 = param_3.anisotropy;\n    _6292 = param_3.anisotropy_rotation;\n    _6293 = param_3.specular;\n    _6294 = param_3.ior;\n    _6295 = param_3.specular_color;\n    _6296 = param_3.transmission;\n    _6297 = param_3.thickness;\n    _6298 = param_3.attenuation_color;\n    _6299 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6249;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6280 = param_6;\n    _6282 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6280;\n    }\n    else\n    {\n        vec3 _5966 = _6282;\n        vec3 _5967 = normalize(_5966);\n        _6282 = _5967;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6249, fa_world_tangent, fa_uv, fa_vertex_color, _5919, gl_FrontFacing);\n        Surface param_9 = Surface(_6280, _6281, _5967, _6283, _6284, _6285, _6286, _6287, _6288, _6289, _6290, _6291, _6292, _6293, _6294, _6295, _6296, _6297, _6298, _6299);\n        vec3 _5978 = lighting(param_8, param_9);\n        result = _5978;\n    }\n    vec3 _5982 = result;\n    vec3 _5983 = _5982 + _6286;\n    result = _5983;\n    vec3 param_10 = _5983;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5992 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5999;\n    if (!_5992)\n    {\n        _5999 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5999 = _5992;\n    }\n    if (_5999)\n    {\n        vec3 _6008 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6014 = dot(_6008, fa_mesh_fs_params[9].xyz);\n        bool _6018 = fa_mesh_fs_params[9].w > 0.5;\n        float _6019;\n        if (_6018)\n        {\n            _6019 = _6014;\n        }\n        else\n        {\n            _6019 = length(_6008);\n        }\n        float _6031 = _6019 - fa_mesh_fs_params[8].x;\n        if (_6031 > 0.0)\n        {\n            float _6040 = fa_mesh_fs_params[7].w * _6031;\n            float tau = _6040 * _6040;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6056;\n                if (_6018)\n                {\n                    _6056 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6014);\n                }\n                else\n                {\n                    _6056 = fa_mesh_fs_params[0].y;\n                }\n                float _6077 = mix(_6056, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6019, 0.0, 1.0));\n                float _6081 = fa_world_pos.y - _6077;\n                float _6086 = _6077 - fa_mesh_fs_params[8].z;\n                float _6091 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6094 = _6086 <= 0.0;\n                bool _6095 = !_6094;\n                bool _6101;\n                if (_6095)\n                {\n                    _6101 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6101 = _6094;\n                }\n                float _6102;\n                if (_6101)\n                {\n                    _6102 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6102 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6086, 80.0));\n                }\n                bool _6129;\n                if (_6095)\n                {\n                    _6129 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6129 = _6094;\n                }\n                float _6130;\n                if (_6129)\n                {\n                    _6130 = fa_mesh_fs_params[8].y * _6086;\n                }\n                else\n                {\n                    _6130 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6086, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6155 = _6091 <= 0.0;\n                bool _6162;\n                if (!_6155)\n                {\n                    _6162 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6162 = _6155;\n                }\n                float _6163;\n                if (_6162)\n                {\n                    _6163 = fa_mesh_fs_params[8].y * _6091;\n                }\n                else\n                {\n                    _6163 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6091, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6190;\n                if (abs(_6081) < 0.001000000047497451305389404296875)\n                {\n                    _6190 = _6102;\n                }\n                else\n                {\n                    _6190 = (_6163 - _6130) / _6081;\n                }\n                tau += (_6031 * max(_6190, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6281);\n}\n\n",
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
            "inst_name": "_477",
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
            "inst_name": "_2130",
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
            "inst_name": "_5523",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _458 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_458, 1.0);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_458 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _723 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_723, 1.0);\n    fa_world_pos = _723;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_723 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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

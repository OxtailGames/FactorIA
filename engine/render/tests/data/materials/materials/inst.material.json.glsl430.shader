{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
  "slang": "glsl430",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4822[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1603 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    bool _1618;\n    if (!_1610)\n    {\n        _1618 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1618 = _1610;\n    }\n    bool _1625;\n    if (!_1618)\n    {\n        _1625 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1625 = _1618;\n    }\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1642 = vec4(world_pos, 1.0);\n    float _1648 = dot(fa_mesh_fs_params[16], _1642);\n    if (!(_1648 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1670 = vec2(dot(fa_mesh_fs_params[14], _1642), dot(fa_mesh_fs_params[15], _1642)) / vec2(_1648);\n    int _1674 = int(fa_mesh_fs_params[18].x);\n    int _1678 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1678) + clamp(int(floor(((_1670.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1678 - 1)) * _1674)) + clamp(int(floor(((_1670.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1674 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1754 = fa_cluster_texel(param);\n    return ivec2(int(_1754.x), int(_1754.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6456 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6459 = fwidth(_6456);\n    bool _6462 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6469;\n    if (!_6462)\n    {\n        _6469 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6469 = _6462;\n    }\n    if (_6469)\n    {\n        fa_rt_slope = min(1.5 * _6459, 0.100000001490116119384765625 * _6456);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6485 = fa_cluster_lookup(param);\n    fa_cl_slot = _6485.x;\n    fa_cl_local = _6485.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7673 = fa_linear_to_srgb(param);\n        c = _7673;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7681 = fa_srgb_to_linear(param_1);\n            c = _7681;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _548;\n    if (i.front_facing)\n    {\n        _548 = i.world_normal;\n    }\n    else\n    {\n        _548 = -i.world_normal;\n    }\n    vec3 _572 = normalize(i.world_tangent.xyz - (_548 * dot(_548, i.world_tangent.xyz)));\n    vec3 _599 = normalize(((_572 * m.x) + ((cross(_548, _572) * i.world_tangent.w) * m.y)) + (_548 * m.z));\n    vec3 _602;\n    if (i.front_facing)\n    {\n        _602 = _599;\n    }\n    else\n    {\n        _602 = -_599;\n    }\n    return _602;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7713 = fa_tex_fix(param_2, param_3);\n    vec4 _10084 = base_t;\n    _10084.x = _7713.x;\n    _10084.y = _7713.y;\n    _10084.z = _7713.z;\n    base_t = _10084;\n    vec4 _7727 = (_10084 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9834 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7761 = fa_tex_fix(param_6, param_7);\n        vec3 _7764 = (_7761 * 2.0) - vec3(1.0);\n        vec2 _7769 = _7764.xy * fa_mesh_fs_params[6].x;\n        vec3 _10092 = _7764;\n        _10092.x = _7769.x;\n        _10092.y = _7769.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10092;\n        _9834 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7799 = fa_tex_fix(param_12, param_13);\n    vec4 _10095 = mrt;\n    _10095.x = _7799.x;\n    _10095.y = _7799.y;\n    _10095.z = _7799.z;\n    mrt = _10095;\n    vec4 _7829 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7829.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7840 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7872 = fa_tex_fix(param_20, param_21);\n    float _9839 = fa_mesh_fs_params[20].x;\n    float _9840 = fa_mesh_fs_params[20].y;\n    float _9843 = fa_mesh_fs_params[20].z;\n    float _9842 = fa_mesh_fs_params[21].w;\n    float _9845 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9839 *= _7840.y;\n            _9840 *= _7840.z;\n            _9842 *= _7829.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9843 *= mrt.x;\n            _9845 *= mrt.w;\n        }\n    }\n    return Surface(_7727.xyz, _7727.w, _9834, clamp(fa_mesh_fs_params[5].x * _7799.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7799.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7840.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7872), _9839, _9840, fa_mesh_fs_params[21].xyz, _9842, _9843, fa_mesh_fs_params[20].w, _9845, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1834 = rect.zw - rect.xy;\n    vec2 _1838 = _1834 * atlas;\n    vec2 _1842 = ddx * _1838;\n    vec2 _1846 = ddy * _1838;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1834), clamp(0.5 * log2(max(max(dot(_1842, _1842), dot(_1846, _1846)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1879 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1886;\n    if (!_1879)\n    {\n        _1886 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1886 = _1879;\n    }\n    if (_1886)\n    {\n        return;\n    }\n    vec3 _1892 = dFdx(world_pos);\n    vec3 _1895 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1899 = fa_cluster_texel(param);\n    int _1903 = int(_1899.w);\n    if (_1903 < 1)\n    {\n        return;\n    }\n    int _1913 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1913;\n    vec4 _1917 = fa_light_texel(param_1);\n    vec2 _1920 = _1917.yz;\n    int _1924 = int(_1917.w);\n    int param_2 = _1913 + 1;\n    vec4 _1929 = fa_light_texel(param_2);\n    float _1930 = _1929.x;\n    int _1936 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1940 = int(_1899.z);\n    vec3 _2205;\n    for (int k = 0; k < _1903; k++)\n    {\n        int _1953 = _1940 + k;\n        int param_3 = _1924 + (_1953 >> 2);\n        int _1970 = (_1913 + 2) + (int(fa_light_texel(param_3)[_1953 & 3]) * 7);\n        int param_4 = _1970 + 6;\n        vec4 _1975 = fa_light_texel(param_4);\n        if (((int(_1975.w + 0.5) >> _1936) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1970;\n        vec4 _1990 = fa_light_texel(param_5);\n        int param_6 = _1970 + 1;\n        vec4 _1995 = fa_light_texel(param_6);\n        int param_7 = _1970 + 2;\n        vec4 _2000 = fa_light_texel(param_7);\n        vec3 _2003 = _1990.xyz;\n        float _2008 = dot(_2003, world_pos) + _1990.w;\n        vec3 _2010 = _1995.xyz;\n        float _2015 = dot(_2010, world_pos) + _1995.w;\n        vec3 _2017 = _2000.xyz;\n        float _2022 = dot(_2017, world_pos) + _2000.w;\n        bool _2027 = abs(_2008) > 0.5;\n        bool _2035;\n        if (!_2027)\n        {\n            _2035 = abs(_2015) > 0.5;\n        }\n        else\n        {\n            _2035 = _2027;\n        }\n        bool _2043;\n        if (!_2035)\n        {\n            _2043 = abs(_2022) > 0.5;\n        }\n        else\n        {\n            _2043 = _2035;\n        }\n        if (_2043)\n        {\n            continue;\n        }\n        float _2058 = clamp(dot(geo_normal, normalize(_2017)) * _1975.z, 0.0, 1.0);\n        if (_2058 <= 0.0)\n        {\n            continue;\n        }\n        float _2078 = (clamp((0.5 - abs(_2022)) * 10.0, 0.0, 1.0) * _2058) * _1975.x;\n        vec2 _2086 = vec2(_2008 + 0.5, 0.5 - _2015);\n        vec2 _2096 = vec2(dot(_2003, _1892), dot(_2010, _1892));\n        vec2 _2106 = vec2(dot(_2003, _1895), dot(_2010, _1895));\n        int param_8 = _1970 + 5;\n        vec4 _2111 = fa_light_texel(param_8);\n        int param_9 = _1970 + 3;\n        vec4 _2116 = fa_light_texel(param_9);\n        int param_10 = _1970 + 4;\n        vec4 _2121 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2111.xyz;\n        bool _2131 = _2116.z > _2116.x;\n        if (_2131)\n        {\n            vec4 param_11 = _2116;\n            vec2 param_12 = _2086;\n            vec2 param_13 = _1920;\n            vec2 param_14 = _2096;\n            vec2 param_15 = _2106;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1930 > 0.5) && (_1930 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2157 = fa_dc_to_linear(param_16);\n                vec4 _9922 = tx;\n                _9922.x = _2157.x;\n                _9922.y = _2157.y;\n                _9922.z = _2157.z;\n                tx = _9922;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2078 * tex_a) * _2111.w, 0.0, 1.0)));\n        if (_2121.z > _2121.x)\n        {\n            vec4 param_17 = _2121;\n            vec2 param_18 = _2086;\n            vec2 param_19 = _1920;\n            vec2 param_20 = _2096;\n            vec2 param_21 = _2106;\n            vec4 _2201 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1930 > 1.5)\n            {\n                vec3 param_22 = _2201.xyz;\n                vec3 _2211 = fa_dc_to_srgb(param_22);\n                _2205 = _2211;\n            }\n            else\n            {\n                _2205 = _2201.xyz;\n            }\n            vec3 _2220 = (_2205 * 2.0) - vec3(1.0);\n            vec2 _2225 = _2220.xy * _1975.y;\n            vec3 _2247 = (normalize(_2003) * _2225.x) + (normalize(_2010) * _2225.y);\n            vec3 _2250 = normalize(normal);\n            normal = normalize(mix(_2250, normalize((_2250 * max(_2220.z, 0.0500000007450580596923828125)) + (_2247 - (_2250 * dot(_2250, _2247)))), vec3(clamp(_2078 * (_2131 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4747 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4755 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4758 = int(_4747);\n    int _4761 = int(_4755);\n    float _4771 = _4755 - float(_4761);\n    int _4826 = (_4758 * 9) + _4761;\n    int _4846 = ((_4758 + 1) * 9) + _4761;\n    return mix(mix(_4822[_4826], _4822[_4826 + 1], _4771), mix(_4822[_4846], _4822[_4846 + 1], _4771), _4747 - float(_4758));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9757 = false;\n    float _9758 = 1.0;\n    float _9759 = 1.0;\n    float _9760 = 1.0;\n    float _9761 = 0.0;\n    float _9762 = 0.0;\n    float _9763 = 0.0;\n    float _9764 = 0.0;\n    float _9766 = 1.0;\n    bool _9767 = false;\n    vec3 _9768 = vec3(0.0);\n    float _9769 = 1.0;\n    float _9770 = 1.0;\n    float _9771 = 1.0;\n    float _9772 = 0.0;\n    float _9773 = 0.0;\n    vec3 _9774 = vec3(1.0, 0.0, 0.0);\n    vec3 _9775 = vec3(0.0, 0.0, 1.0);\n    float _9776 = 1.0;\n    float _9777 = 1.0;\n    float _4897 = clamp(s.specular, 0.0, 1.0);\n    float _4901 = clamp(s.ior, 1.0, 3.0);\n    bool _4906 = (_4897 != 1.0) || (_4901 != 1.5);\n    bool _4915;\n    if (!_4906)\n    {\n        _4915 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4915 = _4906;\n    }\n    if (_4915)\n    {\n        float _4923 = (_4901 - 1.0) / (_4901 + 1.0);\n        f0 = mix(min(vec3(_4923 * _4923) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4897, s.albedo, vec3(metallic));\n        _9758 = mix(_4897, 1.0, metallic);\n        _9757 = true;\n    }\n    float _4950 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4950 > 0.0)\n    {\n        float _4958 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9761 = _4950;\n        _9762 = _4958;\n        float _4965 = _4958 * _4958;\n        _9763 = _4965;\n        _9764 = _4965 * _4965;\n        float _4977 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9766 = _4977;\n        _9759 = 1.0 - (_4950 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4977, 0.0, 1.0), 5.0))));\n        _9757 = true;\n    }\n    vec3 _4996 = max(s.sheen_color, vec3(0.0));\n    float _5005 = max(_4996.x, max(_4996.y, _4996.z));\n    if (_5005 > 0.0)\n    {\n        float _5013 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9767 = true;\n        _9768 = _4996;\n        _9769 = _5013;\n        _9770 = _5013 * _5013;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5013;\n        float _5030 = fa_sheen_albedo(param, param_1);\n        _9772 = _5030;\n        _9771 = 1.0 - min(_5005 * _5030, 1.0);\n        _9757 = true;\n    }\n    _9760 = _9759 * _9771;\n    float _5049 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5049 != 0.0)\n    {\n        vec3 _5064 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5064;\n        if (dot(_5064, _5064) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5076 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5076.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5076.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5076.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5080 = t;\n        vec3 _5081 = normalize(_5080);\n        t = _5081;\n        vec3 _5106 = normalize((_5081 * cos(s.anisotropy_rotation)) + ((cross(n, _5081) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9774 = _5106;\n        _9775 = cross(n, _5106);\n        float _5116 = roughness * roughness;\n        float _5122 = mix(_5116, 1.0, _5049 * _5049);\n        bool _5124 = _5049 > 0.0;\n        _9776 = _5124 ? _5122 : _5116;\n        _9777 = _5124 ? _5116 : _5122;\n        _9773 = _5049;\n        _9757 = true;\n    }\n    return FaLayers(_9757, _9758, _9759, _9760, _9761, _9762, _9763, _9764, i.world_normal, _9766, _9767, _9768, _9769, _9770, _9771, _9772, _9773, _9774, _9775, _9776, _9777);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3918 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3918;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4529 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4534 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4529 > 0.0005000000237487256526947021484375)\n    {\n        if (_4534)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4529;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4529;\n        }\n    }\n    bool _4584 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4584)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4615 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4615)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4534 || _4584) || _4615)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3938 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3941 = _3938.x;\n    float _3943 = _3938.z;\n    vec2 e = vec2(_3941, _3943);\n    if (_3938.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3943)) * ((_3941 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3941)) * ((_3943 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7982 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7987 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7992 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7997 = fa_light_texel(param_3);\n    bool _8000 = _7997.z < 0.5;\n    bool _8008;\n    if (!_8000)\n    {\n        _8008 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8008 = _8000;\n    }\n    if (_8008)\n    {\n        return vec3(0.0);\n    }\n    float _8015 = max(_7982.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8018 = _7987.xyz;\n    vec3 _8022 = _7982.xyz;\n    vec3 _8026 = (fa_world_pos - _8022) / vec3(_8015);\n    vec3 _8035 = min(_8026 + vec3(0.5), (_8018 - vec3(0.5)) - _8026);\n    float _8044 = min(_8035.x, min(_8035.y, _8035.z));\n    if (!(_8044 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8059 = _8018 - vec3(1.0);\n    vec3 _8060 = clamp(_8026, vec3(0.0), _8059);\n    vec3 _8068 = min(floor(_8060), max(_8018 - vec3(2.0), vec3(0.0)));\n    vec3 _8072 = _8060 - _8068;\n    vec3 _8083 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8015));\n    int _8088 = int(_7992.y + 0.5);\n    float _8093 = 0.3257350027561187744140625 * n.y;\n    float _8097 = 0.3257350027561187744140625 * n.z;\n    float _8101 = 0.3257350027561187744140625 * n.x;\n    float _8108 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8115 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8124 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8131 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8144 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8151 = 8 + int(_7997.w);\n    float _8178;\n    float _8191;\n    float _8205;\n    for (int k = 0; k < _8151; k++)\n    {\n        float _8164 = float(k & 1);\n        float _8168 = float((k >> 1) & 1);\n        float _8172 = float((k >> 2) & 1);\n        if (_8164 > 0.5)\n        {\n            _8178 = _8072.x;\n        }\n        else\n        {\n            _8178 = 1.0 - _8072.x;\n        }\n        if (_8168 > 0.5)\n        {\n            _8191 = _8072.y;\n        }\n        else\n        {\n            _8191 = 1.0 - _8072.y;\n        }\n        if (_8172 > 0.5)\n        {\n            _8205 = _8072.z;\n        }\n        else\n        {\n            _8205 = 1.0 - _8072.z;\n        }\n        float _8215 = (_8178 * _8191) * _8205;\n        if (!(_8215 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8228 = min(_8068 + vec3(_8164, _8168, _8172), _8059);\n        int _8248 = int(((_7992.x + _8228.x) + (_7987.x * (_8228.y + (_7987.y * _8228.z)))) + 0.5);\n        vec2 _8263 = vec2(float(_8248 % _8088) * 10.0, 1024.0 + (float(_8248 / _8088) * 11.0));\n        vec2 param_4 = _8263 + vec2(9.5, 10.5);\n        vec4 _8271 = fa_gi_fetch(param_4);\n        bool _8274 = _8271.y < 0.5;\n        bool _8283;\n        if (!_8274)\n        {\n            _8283 = _8271.x > _7997.y;\n        }\n        else\n        {\n            _8283 = _8274;\n        }\n        if (_8283)\n        {\n            continue;\n        }\n        vec3 _8295 = _8083 - (_8022 + (_8228 * _8015));\n        float _8298 = length(_8295);\n        vec3 _8304 = _8295 / vec3(max(_8298, 9.9999997473787516355514526367188e-05));\n        float _8314 = max(9.9999997473787516355514526367188e-05, (dot(-_8304, n) + 1.0) * 0.5);\n        float w = _8215 * (_8314 * _8314);\n        vec3 param_5 = _8304;\n        vec2 param_6 = (_8263 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8333 = fa_gi_fetch(param_6);\n        float _8340 = _8298 / max(_7992.z, 9.9999997473787516355514526367188e-05);\n        float _8343 = _8333.x;\n        if (_8340 > _8343)\n        {\n            float _8356 = max(_8333.y - (_8343 * _8343), 0.0);\n            float _8361 = _8340 - _8343;\n            float _8370 = _8356 / max(_8356 + (_8361 * _8361), 9.9999999600419720025001879548654e-13);\n            w *= ((_8370 * _8370) * _8370);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8263 + vec2(0.5, 10.5);\n        vec2 param_8 = _8263 + vec2(1.5, 10.5);\n        vec2 param_9 = _8263 + vec2(2.5, 10.5);\n        vec2 param_10 = _8263 + vec2(3.5, 10.5);\n        vec2 param_11 = _8263 + vec2(4.5, 10.5);\n        vec2 param_12 = _8263 + vec2(5.5, 10.5);\n        vec2 param_13 = _8263 + vec2(6.5, 10.5);\n        vec2 param_14 = _8263 + vec2(7.5, 10.5);\n        vec2 param_15 = _8263 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8093)) + (fa_gi_fetch(param_9).xyz * _8097)) + (fa_gi_fetch(param_10).xyz * _8101)) + (fa_gi_fetch(param_11).xyz * _8108)) + (fa_gi_fetch(param_12).xyz * _8115)) + (fa_gi_fetch(param_13).xyz * _8124)) + (fa_gi_fetch(param_14).xyz * _8131)) + (fa_gi_fetch(param_15).xyz * _8144)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8044 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8495;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8495 = _7997.x;\n    }\n    else\n    {\n        _8495 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7992.w * _8495);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8524 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8529 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8529) && (k < 8); k++)\n    {\n        int param = _8524 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8519;\n        vec3 _8554 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8559 = param_3 * left;\n        acc += (_8554 * _8559);\n        left -= _8559;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8588 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8588;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8630 = vec4(fa_world_pos, 1.0);\n        vec2 _8649 = vec2(dot(fa_mesh_fs_params[26], _8630), dot(fa_mesh_fs_params[27], _8630)) / vec2(max(dot(fa_mesh_fs_params[28], _8630), 9.9999997473787516355514526367188e-05));\n        float _8658;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8658 = (_8649.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8658 = 0.5 - (_8649.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8649.x * 0.5) + 0.5, _8658) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6426;\n    if (fa_lm.z > 0.5)\n    {\n        _6426 = 0.0;\n    }\n    else\n    {\n        _6426 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6437 = _6426 < 1.0;\n    bool _6443;\n    if (_6437)\n    {\n        int param = li;\n        _6443 = fa_light_baked(param);\n    }\n    else\n    {\n        _6443 = _6437;\n    }\n    return _6443 ? _6426 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _852 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _865 = (c - (ru * hx)) - p;\n        vec3 _871 = ru * (2.0 * hx);\n        float _877 = max(dot(_871, _871), 9.9999999392252902907785028219223e-09);\n        float _881 = dot(_865, _871);\n        float t = clamp((-_881) / _877, 0.0, 1.0);\n        if (_852)\n        {\n            float _896 = dot(r, _871);\n            float _902 = _877 - (_896 * _896);\n            if (abs(_902) > (9.9999997473787516355514526367188e-06 * _877))\n            {\n                t = clamp(((dot(r, _865) * _896) - _881) / _902, 0.0, 1.0);\n            }\n        }\n        return (p + _865) + (_871 * t);\n    }\n    vec3 q = p;\n    float _934 = dot(r, axis);\n    bool _942;\n    if (_852)\n    {\n        _942 = abs(_934) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _942 = _852;\n    }\n    if (_942)\n    {\n        float _952 = dot(c - p, axis) / _934;\n        if (_952 > 0.0)\n        {\n            q = p + (r * _952);\n        }\n    }\n    vec3 _965 = q - c;\n    vec2 xy = vec2(dot(_965, ru), dot(_965, uu));\n    if (shape > 0.5)\n    {\n        float _980 = length(xy);\n        if (_980 > hx)\n        {\n            xy *= (hx / _980);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _614 = abs(d);\n    float _616 = _614.x;\n    float _618 = _614.y;\n    bool _619 = _616 >= _618;\n    bool _627;\n    if (_619)\n    {\n        _627 = _616 >= _614.z;\n    }\n    else\n    {\n        _627 = _619;\n    }\n    int _628;\n    if (_627)\n    {\n        _628 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _642;\n        if (_618 >= _614.z)\n        {\n            _642 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _642 = (d.z > 0.0) ? 4 : 5;\n        }\n        _628 = _642;\n    }\n    return _628;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _772 = dot(d, right);\n    float _776 = dot(d, up);\n    float _787;\n    if (((_772 * _772) + (_776 * _776)) > 1.0000000133514319600180897396058e-10)\n    {\n        _787 = atan(_776, _772) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _787 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_787 - floor(_787)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1018 = fa_light_base(param);\n    bool _1022 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1018;\n    vec4 _1026 = fa_light_texel(param_1);\n    int param_2 = _1018 + 1;\n    vec4 _1031 = fa_light_texel(param_2);\n    float _1034 = _1031.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1046 = _1022 && (_1034 > 2.5);\n    fa_light_is_area = _1046;\n    bool _1048 = _1034 < 0.5;\n    vec3 l;\n    if (_1048)\n    {\n        l = normalize(_1026.xyz);\n        if (_1022)\n        {\n            int param_3 = _1018 + 6;\n            vec4 _1062 = fa_light_texel(param_3);\n            if (_1062.z > 0.5)\n            {\n                int param_4 = _1018 + 4;\n                vec4 _1072 = fa_light_texel(param_4);\n                int param_5 = _1018 + 5;\n                vec4 _1077 = fa_light_texel(param_5);\n                vec2 param_6 = _1062.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1072.xyz) * _1072.w, (-dot(world_pos, _1077.xyz)) * _1077.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1107 = _1026.xyz;\n        vec3 _1109 = _1107 - world_pos;\n        vec3 to_light = _1109;\n        float _1112 = length(_1109);\n        float reach = _1112;\n        bool front = true;\n        if (_1046)\n        {\n            int param_8 = _1018 + 7;\n            reach = max(_1112 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1018 + 4;\n            vec4 _1136 = fa_light_texel(param_9);\n            int param_10 = _1018 + 5;\n            vec4 _1141 = fa_light_texel(param_10);\n            int param_11 = _1018 + 6;\n            vec4 _1146 = fa_light_texel(param_11);\n            float _1147 = _1146.w;\n            int param_12 = _1018 + 2;\n            vec3 _1154 = normalize(fa_light_texel(param_12).xyz);\n            bool _1156 = _1147 > 1.5;\n            bool _1164;\n            if (!_1156)\n            {\n                _1164 = dot(_1154, to_light) < 0.0;\n            }\n            else\n            {\n                _1164 = _1156;\n            }\n            front = _1164;\n            vec3 r = vec3(0.0);\n            vec3 _1173 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1177 = dot(n, n) > 0.5;\n            bool _1185;\n            if (_1177)\n            {\n                _1185 = dot(_1173, _1173) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1185 = _1177;\n            }\n            if (_1185)\n            {\n                r = reflect(-normalize(_1173), normalize(n));\n            }\n            vec3 param_13 = _1107;\n            vec3 param_14 = _1154;\n            vec3 param_15 = _1136.xyz;\n            vec3 param_16 = _1141.xyz;\n            float param_17 = _1136.w;\n            float param_18 = _1141.w;\n            float param_19 = _1147;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1221 = length(to_light);\n        dist = _1221;\n        l = to_light / vec3(max(_1221, 9.9999997473787516355514526367188e-05));\n        float _1235 = reach / max(_1026.w, 0.001000000047497451305389404296875);\n        float _1241 = clamp(1.0 - (_1235 * _1235), 0.0, 1.0);\n        float _1243;\n        if (front)\n        {\n            _1243 = _1241 * _1241;\n        }\n        else\n        {\n            _1243 = 0.0;\n        }\n        atten = _1243;\n        bool _1254 = _1034 < 2.5;\n        if ((_1034 > 1.5) && _1254)\n        {\n            int param_22 = _1018 + 2;\n            vec4 _1262 = fa_light_texel(param_22);\n            float _1272 = _1262.w;\n            int param_23 = _1018 + 3;\n            vec4 _1277 = fa_light_texel(param_23);\n            float _1278 = _1277.x;\n            float cos_inner = _1278;\n            if (_1278 > 1.5)\n            {\n                cos_inner = mix(_1272, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1272, cos_inner, dot(-l, normalize(_1262.xyz)));\n        }\n        if (_1022 && (_1034 < 1.5))\n        {\n            int param_24 = _1018 + 6;\n            vec4 _1302 = fa_light_texel(param_24);\n            if (_1302.z > 0.5)\n            {\n                vec3 _1310 = -to_light;\n                int param_25 = _1018 + 4;\n                int param_26 = _1018 + 5;\n                vec3 _1324 = fa_light_texel(param_25).xyz;\n                vec3 _1328 = fa_light_texel(param_26).xyz;\n                vec3 _1337 = vec3(dot(_1310, _1324), dot(_1310, _1328), dot(_1310, cross(_1324, _1328)));\n                vec3 param_27 = _1337;\n                int _1341 = fa_cube_face(param_27);\n                int param_28 = _1341;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1368 = vec2(dot(_1337, cross(param_29, param_30)), dot(_1337, param_30)) / vec2(max(dot(_1337, param_29), 9.9999997473787516355514526367188e-05));\n                int _1372 = _1341 / 3;\n                vec2 param_31 = _1302.xy + (vec2(float(_1341 - (_1372 * 3)), float(_1372)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1368.x), 0.5 - (0.5 * _1368.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1018 + 7;\n            vec4 _1402 = fa_light_texel(param_33);\n            if (_1402.z > 0.5)\n            {\n                int param_34 = _1018 + 2;\n                int param_35 = _1018 + 4;\n                int param_36 = _1018 + 5;\n                vec2 param_37 = _1402.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1022 && _1254)\n            {\n                int param_42 = _1018 + 6;\n                vec4 _1449 = fa_light_texel(param_42);\n                int param_43 = _1018 + 7;\n                vec4 _1454 = fa_light_texel(param_43);\n                bool _1457 = _1449.z > 0.5;\n                bool _1464;\n                if (!_1457)\n                {\n                    _1464 = _1454.z > 0.5;\n                }\n                else\n                {\n                    _1464 = _1457;\n                }\n                if (_1464)\n                {\n                    int param_44 = _1018 + 2;\n                    vec4 _1471 = fa_light_texel(param_44);\n                    vec3 _1475 = normalize(_1471.xyz);\n                    int param_45 = _1018 + 4;\n                    vec4 _1480 = fa_light_texel(param_45);\n                    int param_46 = _1018 + 5;\n                    vec4 _1485 = fa_light_texel(param_46);\n                    if (_1457)\n                    {\n                        vec3 _1493 = -to_light;\n                        float _1500 = _1471.w;\n                        float _1516 = 0.5 / max(dot(_1493, _1475) * (sqrt(max(1.0 - (_1500 * _1500), 0.0)) / max(_1500, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1449.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1493, _1480.xyz) * _1516), 0.5 - (dot(_1493, _1485.xyz) * _1516));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1454.z > 0.5)\n                    {\n                        vec2 param_49 = _1454.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1475;\n                        vec3 param_52 = _1480.xyz;\n                        vec3 param_53 = _1485.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9745 = _1031.xyz * atten;\n    if (_1022)\n    {\n        _9745 *= fa_light_tint;\n    }\n    int _1585;\n    if (_1048)\n    {\n        _1585 = 0;\n    }\n    else\n    {\n        _1585 = ((_1034 > 1.5) && (_1034 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9745, atten, 1.0, dist, _1585);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2317;\n    if (i == 0)\n    {\n        _2317 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2333;\n        if (i == 1)\n        {\n            _2333 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2341;\n            if (i == 2)\n            {\n                _2341 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2341 = fa_shadows[24].w;\n            }\n            _2333 = _2341;\n        }\n        _2317 = _2333;\n    }\n    return _2317;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2374 = fa_shadow_depth(param, param_1);\n    float _2378;\n    if (conv.x < 0.5)\n    {\n        _2378 = _2374;\n    }\n    else\n    {\n        _2378 = (conv.y * conv.z) / (conv.z - (_2374 * (conv.z - conv.y)));\n    }\n    return _2378;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2424 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2430 = vec2(cos(_2424), sin(_2424));\n    vec2 dir = _2430;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2439;\n        if (k < 0.0)\n        {\n            _2439 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2439 = k;\n        }\n        float _2458 = clamp((_2439 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2477 = sqrt((float(i) + 0.5) * 0.0625) * _2458;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2477));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2491 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2491 < (zr - (_2477 * plane)))\n            {\n                sum += _2491;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2519 = sum / cnt;\n        float _2529;\n        if (k < 0.0)\n        {\n            _2529 = (-k) / max(_2519, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2529 = k;\n        }\n        radius = clamp(((max(zr - _2519, 0.0) * unit) * _2529) / texel_m, 1.5, 16.0);\n        dir = _2430;\n    }\n    float lit = 0.0;\n    int _2555 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2555; i_1++)\n    {\n        float _2574 = sqrt((float(i_1) + 0.5) / float(_2555)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2574));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2574 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2555);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2620 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2625 = clamp(dot(n, l), 0.0, 1.0);\n    float _2631 = sqrt(1.0 - (_2625 * _2625));\n    float _2639 = min(_2631 / max(_2625, 0.20000000298023223876953125), 4.0);\n    float _2644;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2644 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2644 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2669 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2644 * _2631)), 1.0);\n    float _2676 = _2669.x;\n    bool _2679 = _2676 < fa_shadows[ci * 1 + 16].x;\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2676 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2669.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2706;\n    if (!_2697)\n    {\n        _2706 = _2669.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2706 = _2697;\n    }\n    bool _2713;\n    if (!_2706)\n    {\n        _2713 = _2669.z > 1.0;\n    }\n    else\n    {\n        _2713 = _2706;\n    }\n    if (_2713)\n    {\n        return -1.0;\n    }\n    float _2721;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2721 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2721 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2669.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2669.z - ((_2721 * (1.0 + (0.5 * _2639))) / _2620);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2620;\n    float param_5 = _2620 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2639, 3.0)) * 0.5) / _2620;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3099 = int(fa_shadows[25].x + 0.5);\n    if (_3099 < 1)\n    {\n        return 1.0;\n    }\n    float _3114 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3099 - 1;\n    if (_3114 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3126 = _3099 > 1;\n    bool _3133;\n    if (_3126)\n    {\n        _3133 = _3114 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3133 = _3126;\n    }\n    if (_3133)\n    {\n        ci = 1;\n    }\n    bool _3137 = _3099 > 2;\n    bool _3144;\n    if (_3137)\n    {\n        _3144 = _3114 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3144 = _3137;\n    }\n    if (_3144)\n    {\n        ci = 2;\n    }\n    bool _3148 = _3099 > 3;\n    bool _3155;\n    if (_3148)\n    {\n        _3155 = _3114 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3155 = _3148;\n    }\n    if (_3155)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3166 = min(_3099, 4);\n    float _3207;\n    for (int c = ci; c < _3166; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3186 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3186;\n            break;\n        }\n        if (_3186 < 0.0)\n        {\n            continue;\n        }\n        s = _3186;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3207 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3207 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3226 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3207, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3114 - (fa_shadow_split_at(param_7) - _3226)) / _3226, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3258;\n        if ((ci + 1) < _3099)\n        {\n            _3258 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3258 = 1.0;\n        }\n        s = mix(s, _3258, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3363 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3369;\n    if (_3363)\n    {\n        _3369 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3369 = _3363;\n    }\n    if (_3369)\n    {\n        float _3383 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3391 = vec4(fa_world_pos, 1.0);\n        float _3397 = dot(fa_mesh_fs_params[28], _3391);\n        if (_3397 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3416 = vec2(dot(fa_mesh_fs_params[26], _3391), dot(fa_mesh_fs_params[27], _3391)) / vec2(_3397);\n            float _3421 = (_3416.x * 0.5) + 0.5;\n            float _3425;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3425 = (_3416.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3425 = 0.5 - (_3416.y * 0.5);\n            }\n            bool _3441 = _3421 >= 0.0;\n            bool _3447;\n            if (_3441)\n            {\n                _3447 = _3421 < 1.0;\n            }\n            else\n            {\n                _3447 = _3441;\n            }\n            bool _3453;\n            if (_3447)\n            {\n                _3453 = _3425 >= 0.0;\n            }\n            else\n            {\n                _3453 = _3447;\n            }\n            bool _3459;\n            if (_3453)\n            {\n                _3459 = _3425 < 1.0;\n            }\n            else\n            {\n                _3459 = _3453;\n            }\n            if (_3459)\n            {\n                vec4 _3485 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3421, _3425) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3488 = _3485.w > 0.5;\n                bool _3504;\n                if (_3488)\n                {\n                    _3504 = abs(_3383 - _3485.x) <= (((0.00200000009499490261077880859375 * _3383) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3504 = _3488;\n                }\n                if (_3504)\n                {\n                    float _3510;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3510 = min(_3485.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3510 = _3485.y;\n                    }\n                    return _3510;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2779 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2786;\n    if (!_2779)\n    {\n        _2786 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2786 = _2779;\n    }\n    if (_2786)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2799 = fa_light_texel(param);\n    float _2800 = _2799.x;\n    if (_2800 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2809 = int(_2800 + 0.5);\n    int param_1 = _2809;\n    vec4 _2813 = fa_light_texel(param_1);\n    int param_2 = _2809 + 1;\n    vec4 _2818 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2821 = _2813.y;\n    if (_2821 > 0.0)\n    {\n        float _2838 = 1.0 - smoothstep(0.75 * _2821, _2821, length(world - fa_shadows[27].xyz));\n        fade = _2838;\n        if (_2838 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2813.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2862 = (_2809 + 2) + (face * 6);\n    int param_4 = _2862;\n    int param_5 = _2862 + 1;\n    int param_6 = _2862 + 3;\n    vec4 _2876 = fa_light_texel(param_6);\n    int param_7 = _2862 + 4;\n    vec4 _2881 = fa_light_texel(param_7);\n    int param_8 = _2862 + 5;\n    vec4 _2886 = fa_light_texel(param_8);\n    float _2898 = _2886.x * max(dot(_2876, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2903 = clamp(dot(n, l), 0.0, 1.0);\n    float _2926 = clamp(dot(n, _2876.xyz), -1.0, 1.0);\n    float _2945 = min(sqrt(1.0 - (_2926 * _2926)) / max(abs(dot(n, world - lpos)) / max(dot(_2876, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2948 = _2818.y;\n    float _2950;\n    if (_2948 > 0.0)\n    {\n        _2950 = _2948;\n    }\n    else\n    {\n        _2950 = 1.5 * _2898;\n    }\n    vec4 _2970 = vec4(world + (n * (_2950 * sqrt(1.0 - (_2903 * _2903)))), 1.0);\n    float _2974 = dot(_2876, _2970);\n    float _2977 = _2886.y;\n    if (_2974 < _2977)\n    {\n        return 1.0;\n    }\n    vec2 _2992 = vec2(dot(fa_light_texel(param_4), _2970), dot(fa_light_texel(param_5), _2970)) / vec2(_2974);\n    float _2994 = _2992.x;\n    bool _2997 = _2994 < _2881.x;\n    bool _3006;\n    if (!_2997)\n    {\n        _3006 = _2994 > _2881.z;\n    }\n    else\n    {\n        _3006 = _2997;\n    }\n    bool _3015;\n    if (!_3006)\n    {\n        _3015 = _2992.y < _2881.y;\n    }\n    else\n    {\n        _3015 = _3006;\n    }\n    bool _3024;\n    if (!_3015)\n    {\n        _3024 = _2992.y > _2881.w;\n    }\n    else\n    {\n        _3024 = _3015;\n    }\n    if (_3024)\n    {\n        return 1.0;\n    }\n    float _3030 = _2818.x;\n    float _3032;\n    if (_3030 > 0.0)\n    {\n        _3032 = _3030;\n    }\n    else\n    {\n        _3032 = 1.5 * _2898;\n    }\n    vec2 param_9 = _2992;\n    vec4 param_10 = _2881;\n    float param_11 = _2974 - (_3032 * (1.0 + (0.5 * _2945)));\n    float param_12 = _2898;\n    float param_13 = 1.0;\n    float param_14 = _2886.z * 0.25;\n    float param_15 = (_2898 * min(_2945, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2977, _2886.z);\n    int param_17 = int(_2813.z + 0.5);\n    float param_18 = _2813.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3539 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3545;\n    if (_3539)\n    {\n        _3545 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3545 = _3539;\n    }\n    bool _3551;\n    if (_3545)\n    {\n        _3551 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3551 = _3545;\n    }\n    if (_3551)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3563 = fa_light_texel(param);\n        float _3564 = _3563.z;\n        if (_3564 > 0.5)\n        {\n            float _3577 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3583 = ((0.00200000009499490261077880859375 * _3577) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3589 = vec4(world, 1.0);\n            float _3594 = dot(fa_mesh_fs_params[28], _3589);\n            if (_3594 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3611 = vec2(dot(fa_mesh_fs_params[26], _3589), dot(fa_mesh_fs_params[27], _3589)) / vec2(_3594);\n                float _3616 = (_3611.x * 0.5) + 0.5;\n                float _3620;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3620 = (_3611.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3620 = 0.5 - (_3611.y * 0.5);\n                }\n                bool _3636 = _3616 >= 0.0;\n                bool _3642;\n                if (_3636)\n                {\n                    _3642 = _3616 < 1.0;\n                }\n                else\n                {\n                    _3642 = _3636;\n                }\n                bool _3648;\n                if (_3642)\n                {\n                    _3648 = _3620 >= 0.0;\n                }\n                else\n                {\n                    _3648 = _3642;\n                }\n                bool _3654;\n                if (_3648)\n                {\n                    _3654 = _3620 < 1.0;\n                }\n                else\n                {\n                    _3654 = _3648;\n                }\n                if (_3654)\n                {\n                    ivec2 _3671 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3672 = clamp(ivec2(vec2(_3616, _3620) * fa_mesh_fs_params[24].zw), ivec2(0), _3671);\n                    float _3676;\n                    if (_3564 < 1.5)\n                    {\n                        _3676 = 1.0;\n                    }\n                    else\n                    {\n                        _3676 = (_3564 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3698;\n                    int _3704;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3698 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3704 = k - 1;\n                            }\n                            else\n                            {\n                                _3704 = k;\n                            }\n                            _3698 = _3704;\n                        }\n                        vec4 _3733 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3672 + ivec2((_3698 % 3) - 1, (_3698 / 3) - 1), ivec2(0), _3671), 0);\n                        bool _3736 = _3733.w > 0.5;\n                        bool _3746;\n                        if (_3736)\n                        {\n                            _3746 = abs(_3577 - _3733.x) <= _3583;\n                        }\n                        else\n                        {\n                            _3746 = _3736;\n                        }\n                        if (_3746)\n                        {\n                            best = min(best, mod(floor(_3733.z / _3676), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3773;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3773 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3773 = best;\n                        }\n                        return _3773;\n                    }\n                }\n            }\n            float _3796;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3796 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3796 = 1.0;\n            }\n            return _3796;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5640 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5647;\n    if (!_5640)\n    {\n        _5647 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5647 = _5640;\n    }\n    if (_5647)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5660 = fa_light_texel(param);\n    float _5661 = _5660.y;\n    float len = _5661;\n    if (_5661 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5673 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5682 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5673);\n    if (_5682 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5688 = len;\n    float _5691 = min(_5688, 0.89999997615814208984375 * dist);\n    len = _5691;\n    float _5696 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5673);\n    float _5701 = _5696 + (0.5 * _5691);\n    vec3 _5707 = world + (gn * _5696);\n    float _5709 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5770;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5724 = (float(k) + _5709) * 0.083333335816860198974609375;\n        vec3 _5732 = _5707 + (l * (_5724 * len));\n        vec4 _5738 = vec4(_5732, 1.0);\n        float _5743 = dot(fa_mesh_fs_params[28], _5738);\n        if (_5743 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5761 = vec2(dot(fa_mesh_fs_params[26], _5738), dot(fa_mesh_fs_params[27], _5738)) / vec2(_5743);\n        float _5765 = _5761.x * 0.5;\n        float _5766 = _5765 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5770 = (_5761.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5770 = 0.5 - (_5761.y * 0.5);\n        }\n        bool _5786 = _5766 < 0.0;\n        bool _5793;\n        if (!_5786)\n        {\n            _5793 = _5766 >= 1.0;\n        }\n        else\n        {\n            _5793 = _5786;\n        }\n        bool _5800;\n        if (!_5793)\n        {\n            _5800 = _5770 < 0.0;\n        }\n        else\n        {\n            _5800 = _5793;\n        }\n        bool _5807;\n        if (!_5800)\n        {\n            _5807 = _5770 >= 1.0;\n        }\n        else\n        {\n            _5807 = _5800;\n        }\n        if (_5807)\n        {\n            break;\n        }\n        vec4 _5831 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5766, _5770) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5831.w < 0.5)\n        {\n            continue;\n        }\n        float _5849 = (dot(fa_mesh_fs_params[29].xyz, _5732) + fa_mesh_fs_params[29].w) - _5831.x;\n        if ((_5849 > _5696) && (_5849 < _5701))\n        {\n            occ = max(occ, (1.0 - (_5724 * _5724)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5766, 0.5 - _5765), min(_5770, 1.0 - _5770))));\n        }\n    }\n    return 1.0 - (occ * _5682);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6511 = fa_baked_keep(param);\n    if (_6511 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6537 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9814 = _6537.color;\n    float _9815 = _6537.attenuation;\n    float _9816 = _6537.shadow;\n    bool _6540 = _6537.type == 0;\n    if (_6540 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6537.direction;\n        float _6551 = fa_shadow_factor(param_5, param_6);\n        _9816 = _6551;\n        _9814 *= _6551;\n    }\n    else\n    {\n        bool _6562 = _6537.type != 0;\n        bool _6568;\n        if (_6562)\n        {\n            _6568 = _9815 > 0.0;\n        }\n        else\n        {\n            _6568 = _6562;\n        }\n        if (_6568)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6537.direction;\n            float _6587 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9816 = _6587;\n            _9814 *= _6587;\n        }\n    }\n    bool _6597 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6603;\n    if (_6597)\n    {\n        _6603 = _9815 > 0.0;\n    }\n    else\n    {\n        _6603 = _6597;\n    }\n    if (_6603)\n    {\n        float _6610;\n        if (_6540)\n        {\n            _6610 = 1000000000.0;\n        }\n        else\n        {\n            _6610 = _6537._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6537.direction;\n        float param_18 = _6610;\n        float _6628 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9816 *= _6628;\n        _9814 *= _6628;\n    }\n    float _6641 = _9815;\n    float _6642 = _6641 * _6511;\n    _9815 = _6642;\n    vec3 _6646 = _9814;\n    vec3 _6647 = _6646 * _6511;\n    _9814 = _6647;\n    return LightSample(_6537.direction, _6647, _6642, _9816, _6537._distance, _6537.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6681 = v - (n * dot(v, n));\n    vec3 t = _6681;\n    float _6685 = dot(_6681, _6681);\n    float l2 = _6685;\n    if (_6685 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6695;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6695 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6695 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6695;\n        l2 = dot(_6695, _6695);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7082;\n    if ((j == 0) || (j == 7))\n    {\n        _7082 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7092;\n        if ((j == 3) || (j == 4))\n        {\n            _7092 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7092 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7082 = _7092;\n    }\n    float _7113;\n    if ((j == 1) || (j == 2))\n    {\n        _7113 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7122;\n        if ((j == 5) || (j == 6))\n        {\n            _7122 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7122 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7113 = _7122;\n    }\n    return (pc + (ex * _7082)) + (ey * _7113);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6730 = dot(a, a);\n    float _6734 = dot(b, b);\n    if ((_6730 < 1.0000000195414813782625560981111e-24) || (_6734 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6748 = a * inversesqrt(_6730);\n    vec3 _6753 = b * inversesqrt(_6734);\n    float _6757 = dot(_6748, _6753);\n    float _6760 = abs(_6757);\n    float g = (((((((((((0.0416471660137176513671875 * _6760) - 0.1924748718738555908203125) * _6760) + 0.4179156124591827392578125) * _6760) - 0.616057217121124267578125) * _6760) + 0.777722418308258056640625) * _6760) - 0.999542415142059326171875) * _6760) + 1.570791721343994140625;\n    if (_6757 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6757 * _6757), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6748, _6753) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6817 = a.z > 0.0;\n    bool _6821 = b.z > 0.0;\n    if (_6817 && _6821)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6817 != _6821)\n        {\n            vec3 _6856 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6856.z = 0.0;\n            if (_6817)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6856;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6856;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6856;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6856;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6905 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6931 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6957 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6983 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6905;\n    vec3 param_1 = _6931;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6931;\n    vec3 param_7 = _6957;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6957;\n    vec3 param_13 = _6983;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6983;\n    vec3 param_19 = _6905;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7151 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7169;\n    for (int k = 0; k < (2 * _7151); k++)\n    {\n        bool _7166 = k >= _7151;\n        if (_7166)\n        {\n            _7169 = k - _7151;\n        }\n        else\n        {\n            _7169 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7151 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7215 = 2 * _7169;\n            int param_4 = _7215 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7215 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7215 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7252 = bvec4(_7166);\n        vec4 param_16 = vec4(_7252.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7252.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7252.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7252.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7263 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7166)\n        {\n            vec2 _10067 = sum;\n            _10067.y = _10067.y + _7263;\n            sum = _10067;\n        }\n        else\n        {\n            vec2 _10070 = sum;\n            _10070.x = _10070.x + _7263;\n            sum = _10070;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7287 = fa_light_base(param);\n    int param_1 = _7287;\n    int param_2 = _7287 + 1;\n    int param_3 = _7287 + 2;\n    int param_4 = _7287 + 4;\n    vec4 _7309 = fa_light_texel(param_4);\n    int param_5 = _7287 + 5;\n    vec4 _7314 = fa_light_texel(param_5);\n    int param_6 = _7287 + 6;\n    vec4 _7319 = fa_light_texel(param_6);\n    float _7320 = _7319.w;\n    vec3 _7325 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7327 = _7320 < 1.5;\n    bool _7334;\n    if (_7327)\n    {\n        _7334 = dot(normalize(fa_light_texel(param_3).xyz), _7325) >= 0.0;\n    }\n    else\n    {\n        _7334 = _7327;\n    }\n    if (_7334)\n    {\n        return vec3(0.0);\n    }\n    bool _7343 = (_7320 > 0.5) && _7327;\n    float _7347 = _7343 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7350 = _7309.xyz;\n    float _7352 = _7309.w;\n    vec3 _7358 = _7314.xyz;\n    float _7360 = _7314.w;\n    vec3 up = _7358 * (_7360 * _7347);\n    float _7366;\n    if (_7343)\n    {\n        _7366 = (3.1415927410125732421875 * _7352) * _7352;\n    }\n    else\n    {\n        _7366 = (4.0 * _7352) * _7360;\n    }\n    if (_7320 > 1.5)\n    {\n        vec3 _7392 = cross(_7350, -_7325);\n        vec3 perp = _7392;\n        float _7396 = dot(_7392, _7392);\n        vec3 _7399;\n        if (_7396 > 1.0000000133514319600180897396058e-10)\n        {\n            _7399 = perp * inversesqrt(_7396);\n        }\n        else\n        {\n            _7399 = _7358;\n        }\n        perp = _7399;\n        up = _7399 * _7360;\n    }\n    float _7420 = max(_7366, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7430 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7430;\n    vec3 param_10 = n;\n    vec3 param_11 = _7325;\n    vec3 param_12 = _7430;\n    vec3 param_13 = n;\n    vec3 param_14 = _7350 * (_7352 * _7347);\n    vec3 param_15 = _7430;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7461 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7461;\n    vec2 param_21 = _7461 + vec2(64.0, 0.0);\n    vec4 _7471 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7320;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7483 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7483.x) + (((f0 * _7471.x) + ((vec3(f90) - f0) * _7471.y)) * _7483.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7325, _7325)) + _7420) / _7420) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5377 = 1.0 / alpha;\n    return ((2.0 + _5377) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5377)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5412 = max(dot(L.nc, l), 0.0);\n    float _5418 = max(dot(L.nc, h), 0.0);\n    float _5427 = ((_5418 * _5418) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5427) * _5427)) * (0.5 / max(mix((2.0 * _5412) * L.coat_ndv, _5412 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5412)) * _5412;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7520;\n    if (L.sheen_on)\n    {\n        _7520 = L.sheen_scale;\n    }\n    else\n    {\n        _7520 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7520);\n    vec3 _7533 = normalize(l + v);\n    int param = li;\n    vec3 _7544 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7553 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7533), 0.0);\n        float param_3 = _7553;\n        float param_4 = ndv;\n        result += ((L.sheen * _7544) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7553)) * _7553) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7533;\n        float param_8 = max(dot(v, _7533), 0.0);\n        result += (_7544 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5280 = tdh / at;\n    float _5284 = bdh / ab;\n    float _5296 = ((_5280 * _5280) + (_5284 * _5284)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5296) * _5296);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5476 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5555 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5555) * _5555);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5476);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5476));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4679 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4682 = _4679.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4682 * _4682, exp2((-9.27999973297119140625) * ndv)) * _4682) + _4679.y)) + _4679.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3990;\n    if (lv == 0)\n    {\n        _3990 = 0.0;\n    }\n    else\n    {\n        _3990 = res + 2.0;\n    }\n    float _4000;\n    if (lv == 0)\n    {\n        _4000 = 0.0;\n    }\n    else\n    {\n        _4000 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3990, _4000)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4046;\n    if (res > 64.5)\n    {\n        _4046 = 5.0;\n    }\n    else\n    {\n        _4046 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4061 = clamp(rough, 0.0, 1.0) * (_4046 - 1.0);\n    int _4068 = int(min(floor(_4061), _4046 - 2.0));\n    float _4073 = _4061 - float(_4068);\n    vec3 param = d;\n    vec2 _4077 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4068;\n    vec2 param_4 = _4077;\n    vec3 _4087 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4073 < 0.00200000009499490261077880859375)\n    {\n        return _4087;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4068 + 1;\n    vec2 param_8 = _4077;\n    return mix(_4087, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4073));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4158 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4165 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4172 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4178 = dot(bx.xyz, d);\n    float _4182 = dot(by.xyz, d);\n    float _4186 = dot(bz.xyz, d);\n    float _4192;\n    if (_4178 > 9.9999999747524270787835121154785e-07)\n    {\n        _4192 = (1.0 - _4158) / _4178;\n    }\n    else\n    {\n        float _4206;\n        if (_4178 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4206 = ((-1.0) - _4158) / _4178;\n        }\n        else\n        {\n            _4206 = 1000000015047466219876688855040.0;\n        }\n        _4192 = _4206;\n    }\n    float tx = _4192;\n    float _4223;\n    if (_4182 > 9.9999999747524270787835121154785e-07)\n    {\n        _4223 = (1.0 - _4165) / _4182;\n    }\n    else\n    {\n        float _4236;\n        if (_4182 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4236 = ((-1.0) - _4165) / _4182;\n        }\n        else\n        {\n            _4236 = 1000000015047466219876688855040.0;\n        }\n        _4223 = _4236;\n    }\n    float ty = _4223;\n    float _4252;\n    if (_4186 > 9.9999999747524270787835121154785e-07)\n    {\n        _4252 = (1.0 - _4172) / _4186;\n    }\n    else\n    {\n        float _4265;\n        if (_4186 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4265 = ((-1.0) - _4172) / _4186;\n        }\n        else\n        {\n            _4265 = 1000000015047466219876688855040.0;\n        }\n        _4252 = _4265;\n    }\n    float _4277 = tx;\n    float _4280 = (_4277 > 0.0) ? _4277 : 1000000015047466219876688855040.0;\n    tx = _4280;\n    float _4281 = ty;\n    float _4284 = (_4281 > 0.0) ? _4281 : 1000000015047466219876688855040.0;\n    ty = _4284;\n    float _4294 = min(_4280, min(_4284, (_4252 > 0.0) ? _4252 : 1000000015047466219876688855040.0));\n    if (_4294 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4310 = (fa_world_pos + (d * _4294)) - posw.xyz;\n    vec3 _4315;\n    if (dot(_4310, _4310) > 1.0000000133514319600180897396058e-10)\n    {\n        _4315 = normalize(_4310);\n    }\n    else\n    {\n        _4315 = d;\n    }\n    return _4315;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4361 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4361 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4389 = rough * rough;\n            float _4420 = 0.60000002384185791015625 * _4389;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4389)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4420, 0.0500000007450580596923828125 + _4420, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4389 * 0.60000002384185791015625));\n        }\n        outc = base * _4361;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4479 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4479 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4511 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4511 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5157;\n        if (L.aniso >= 0.0)\n        {\n            _5157 = L.b;\n        }\n        else\n        {\n            _5157 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5157, v), _5157), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5193 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5193.x) + (vec3(L.f90) * _5193.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5251 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5251.x) + _5251.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4721 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4721.x) + vec3(_4721.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5953 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5957 = fa_xm_origin(param_1);\n    vec2 _5963 = (uv * _5953) - vec2(0.5);\n    vec2 _5966 = fract(_5963);\n    vec2 _5969 = floor(_5963);\n    vec2 param_2 = _5953;\n    vec2 param_3 = _5957;\n    vec2 param_4 = _5969;\n    vec2 param_5 = _5953;\n    vec2 param_6 = _5957;\n    vec2 param_7 = _5969 + vec2(1.0, 0.0);\n    vec2 param_8 = _5953;\n    vec2 param_9 = _5957;\n    vec2 param_10 = _5969 + vec2(0.0, 1.0);\n    vec2 param_11 = _5953;\n    vec2 param_12 = _5957;\n    vec2 param_13 = _5969 + vec2(1.0);\n    vec3 _6011 = vec3(_5966.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6011), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6011), vec3(_5966.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6030 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6034 = clamp(lod, 0.0, _6030);\n    int _6038 = int(floor(_6034));\n    int param = _6038;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6048 = float(_6038);\n    float _6049 = _6034 - _6048;\n    bool _6051 = _6049 > 0.001000000047497451305389404296875;\n    bool _6058;\n    if (_6051)\n    {\n        _6058 = _6048 < _6030;\n    }\n    else\n    {\n        _6058 = _6051;\n    }\n    if (_6058)\n    {\n        int param_2 = _6038 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6049));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6084 = fa_env_brdf(param, param_1);\n    vec3 _6108 = ((vec3(1.0) - clamp((f0 * _6084.x) + (vec3(f90) * _6084.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6108;\n    float _6114 = max(s.thickness, 0.0);\n    bool _6119 = _6114 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6119)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6114);\n    }\n    bool _6144 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6150;\n    if (_6144)\n    {\n        _6150 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6150 = _6144;\n    }\n    bool _6157;\n    if (!_6150)\n    {\n        _6157 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6157 = _6150;\n    }\n    if (_6157)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6172 = vec4(fa_world_pos, 1.0);\n    float _6177 = dot(fa_mesh_fs_params[28], _6172);\n    vec2 uv0 = vec2(0.5);\n    if (_6177 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6195 = vec2(dot(fa_mesh_fs_params[26], _6172), dot(fa_mesh_fs_params[27], _6172)) / vec2(_6177);\n        float _6203;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6203 = (_6195.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6203 = 0.5 - (_6195.y * 0.5);\n        }\n        uv0 = vec2((_6195.x * 0.5) + 0.5, _6203);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6224 = fa_xm_size(param_2);\n        vec2 _6232 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6224);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6232), 0).w > 0.5)\n        {\n            int _6252 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6275 = abs(dx) > _6252;\n                    bool _6283;\n                    if (!_6275)\n                    {\n                        _6283 = abs(dy) > _6252;\n                    }\n                    else\n                    {\n                        _6283 = _6275;\n                    }\n                    if (_6283)\n                    {\n                        continue;\n                    }\n                    vec4 _6304 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6232 + vec2(float(dx), float(dy)), vec2(0.0), _6224 - vec2(1.0))), 0);\n                    if (_6304.w > 0.5)\n                    {\n                        acc += _6304.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6108 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6119)\n    {\n        vec4 _6352 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6114), 1.0);\n        float _6357 = dot(fa_mesh_fs_params[28], _6352);\n        uv = vec2(0.5);\n        if (_6357 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6374 = vec2(dot(fa_mesh_fs_params[26], _6352), dot(fa_mesh_fs_params[27], _6352)) / vec2(_6357);\n            float _6382;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6382 = (_6374.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6382 = 0.5 - (_6374.y * 0.5);\n            }\n            uv = vec2((_6374.x * 0.5) + 0.5, _6382);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3286 = int(fa_shadows[25].x + 0.5);\n    float _3296 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3301 = _3286 > 0;\n    bool _3310;\n    if (_3301)\n    {\n        int param = _3286 - 1;\n        _3310 = _3296 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3310 = _3301;\n    }\n    if (_3310)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3316 = _3286 > 1;\n        bool _3323;\n        if (_3316)\n        {\n            _3323 = _3296 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3323 = _3316;\n        }\n        if (_3323)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3329 = _3286 > 2;\n        bool _3336;\n        if (_3329)\n        {\n            _3336 = _3296 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3336 = _3329;\n        }\n        if (_3336)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3342 = _3286 > 3;\n        bool _3349;\n        if (_3342)\n        {\n            _3349 = _3296 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3349 = _3342;\n        }\n        if (_3349)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9473 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9473 = -_9473;\n    }\n    vec3 _8771 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9473, fa_world_tangent, fa_uv, fa_vertex_color, _8771, gl_FrontFacing);\n    Surface _8779 = fa_standard_surface(param_1);\n    vec3 _9504 = _8779.albedo;\n    float _9505 = _8779.alpha;\n    vec3 _9506 = _8779.normal;\n    float _9507 = _8779.metallic;\n    float _9508 = _8779.roughness;\n    float _9509 = _8779.occlusion;\n    vec3 _9510 = _8779.emission;\n    float _9511 = _8779.clearcoat;\n    float _9512 = _8779.clearcoat_roughness;\n    vec3 _9513 = _8779.sheen_color;\n    float _9514 = _8779.sheen_roughness;\n    float _9515 = _8779.anisotropy;\n    float _9516 = _8779.anisotropy_rotation;\n    float _9517 = _8779.specular;\n    float _9518 = _8779.ior;\n    vec3 _9519 = _8779.specular_color;\n    float _9520 = _8779.transmission;\n    float _9521 = _8779.thickness;\n    vec3 _9522 = _8779.attenuation_color;\n    float _9523 = _8779.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9473, fa_world_tangent, fa_uv, fa_vertex_color, _8771, gl_FrontFacing);\n    Surface param_3 = _8779;\n    surface(param_2, param_3);\n    _9504 = param_3.albedo;\n    _9505 = param_3.alpha;\n    _9506 = param_3.normal;\n    _9507 = param_3.metallic;\n    _9508 = param_3.roughness;\n    _9509 = param_3.occlusion;\n    _9510 = param_3.emission;\n    _9511 = param_3.clearcoat;\n    _9512 = param_3.clearcoat_roughness;\n    _9513 = param_3.sheen_color;\n    _9514 = param_3.sheen_roughness;\n    _9515 = param_3.anisotropy;\n    _9516 = param_3.anisotropy_rotation;\n    _9517 = param_3.specular;\n    _9518 = param_3.ior;\n    _9519 = param_3.specular_color;\n    _9520 = param_3.transmission;\n    _9521 = param_3.thickness;\n    _9522 = param_3.attenuation_color;\n    _9523 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9473;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9504 = param_6;\n    _9506 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9504;\n    }\n    else\n    {\n        vec3 _8819 = normalize(_9506);\n        float _8826 = clamp(_9507, 0.0, 1.0);\n        float _8830 = clamp(_9508, 0.0500000007450580596923828125, 1.0);\n        float _8834 = _8830 * _8830;\n        float _8838 = _8834 * _8834;\n        float _8843 = max(dot(_8819, _8771), 9.9999997473787516355514526367188e-05);\n        float _8849 = 1.0 - _8826;\n        float _8850 = clamp(_9520, 0.0, 1.0) * _8849;\n        vec3 _8859 = (_9504 * _8849) * (1.0 - _8850);\n        vec3 _8866 = mix(vec3(0.039999999105930328369140625), _9504, vec3(_8826));\n        vec3 f0 = _8866;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9473, fa_world_tangent, fa_uv, fa_vertex_color, _8771, gl_FrontFacing);\n        Surface param_9 = Surface(_9504, _9505, _9506, _9507, _9508, _9509, _9510, _9511, _9512, _9513, _9514, _9515, _9516, _9517, _9518, _9519, _9520, _9521, _9522, _9523);\n        vec3 param_10 = _8819;\n        vec3 param_11 = _8771;\n        float param_12 = _8826;\n        float param_13 = _8830;\n        vec3 param_14 = _8866;\n        FaLayers _8882 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8819;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8859) * _9509;\n        if (_8882.on)\n        {\n            lit *= _8882.base_scale;\n        }\n        int _8904 = fa_cl_ndir + fa_cl_local;\n        float _8969;\n        for (int ln = 0; ln < _8904; ln++)\n        {\n            int param_16 = ln;\n            int _8917 = fa_cl_light(param_16);\n            int param_17 = _8917;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8917;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9473;\n            LightSample _8933 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8941 = max(dot(_8819, _8933.direction), 0.0);\n            float _8947 = _8933.attenuation * _8933.shadow;\n            vec3 _8952 = normalize(_8933.direction + _8771);\n            float _8957 = max(dot(_8819, _8952), 0.0);\n            float _8962 = max(dot(_8771, _8952), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8882.on)\n                {\n                    _8969 = _8882.f90;\n                }\n                else\n                {\n                    _8969 = 1.0;\n                }\n                int param_21 = _8917;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8819;\n                vec3 param_24 = _8771;\n                vec3 param_25 = _8859;\n                vec3 param_26 = f0;\n                float param_27 = _8969;\n                float param_28 = _8830;\n                float param_29 = _8843;\n                float param_30 = _8947;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8882.on)\n                {\n                    FaLayers param_31 = _8882;\n                    vec3 param_32 = area;\n                    int param_33 = _8917;\n                    vec3 param_34 = _8819;\n                    vec3 param_35 = _8771;\n                    vec3 param_36 = _8933.direction;\n                    float param_37 = _8843;\n                    float param_38 = _8947;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8882.on)\n                {\n                    FaLayers param_39 = _8882;\n                    vec3 param_40 = _8859;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8819;\n                    vec3 param_43 = _8771;\n                    vec3 param_44 = _8933.direction;\n                    vec3 param_45 = _8952;\n                    float param_46 = _8941;\n                    float param_47 = _8843;\n                    float param_48 = _8957;\n                    float param_49 = _8962;\n                    float param_50 = _8834;\n                    float param_51 = _8838;\n                    int param_52 = _8917;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8947));\n                }\n                else\n                {\n                    float _9071 = ((_8957 * _8957) * (_8838 - 1.0)) + 1.0;\n                    int param_53 = _8917;\n                    lit += (((_8859 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8962, 5.0))) * (((_8838 / ((3.1415927410125732421875 * _9071) * _9071)) * (0.5 / max(mix((2.0 * _8941) * _8843, _8941 + _8843, _8834), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8941))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8941 * _8947));\n                }\n            }\n        }\n        if (_8882.on)\n        {\n            FaLayers param_54 = _8882;\n            vec3 param_55 = _8819;\n            vec3 param_56 = _8771;\n            vec3 param_57 = f0;\n            float param_58 = _8830;\n            float param_59 = _9509;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8819;\n            vec3 param_61 = _8771;\n            vec3 param_62 = f0;\n            float param_63 = _8830;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9509);\n        }\n        if (_8850 > 0.0)\n        {\n            float _9169;\n            if (_8882.on)\n            {\n                _9169 = _8882.f90;\n            }\n            else\n            {\n                _9169 = 1.0;\n            }\n            float _9177;\n            if (_8882.on)\n            {\n                _9177 = _8882.base_scale;\n            }\n            else\n            {\n                _9177 = 1.0;\n            }\n            Surface param_64 = Surface(_9504, _9505, _9506, _9507, _9508, _9509, _9510, _9511, _9512, _9513, _9514, _9515, _9516, _9517, _9518, _9519, _9520, _9521, _9522, _9523);\n            vec3 param_65 = _8819;\n            vec3 param_66 = _8771;\n            float param_67 = _8830;\n            vec3 param_68 = f0;\n            float param_69 = _9169;\n            float param_70 = _9177;\n            float param_71 = _8850;\n            float param_72 = fa_tr_blend;\n            vec3 _9201 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9201;\n        }\n        result = lit;\n    }\n    vec3 _9208 = result;\n    vec3 _9209 = _9208 + _9510;\n    result = _9209;\n    vec3 param_73 = _9209;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9218 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9225;\n    if (!_9218)\n    {\n        _9225 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9225 = _9218;\n    }\n    if (_9225)\n    {\n        vec3 _9234 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9240 = dot(_9234, fa_mesh_fs_params[9].xyz);\n        bool _9244 = fa_mesh_fs_params[9].w > 0.5;\n        float _9245;\n        if (_9244)\n        {\n            _9245 = _9240;\n        }\n        else\n        {\n            _9245 = length(_9234);\n        }\n        float _9257 = _9245 - fa_mesh_fs_params[8].x;\n        if (_9257 > 0.0)\n        {\n            float _9266 = fa_mesh_fs_params[7].w * _9257;\n            float tau = _9266 * _9266;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9282;\n                if (_9244)\n                {\n                    _9282 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9240);\n                }\n                else\n                {\n                    _9282 = fa_mesh_fs_params[0].y;\n                }\n                float _9303 = mix(_9282, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9245, 0.0, 1.0));\n                float _9307 = fa_world_pos.y - _9303;\n                float _9312 = _9303 - fa_mesh_fs_params[8].z;\n                float _9317 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9320 = _9312 <= 0.0;\n                bool _9321 = !_9320;\n                bool _9327;\n                if (_9321)\n                {\n                    _9327 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9327 = _9320;\n                }\n                float _9328;\n                if (_9327)\n                {\n                    _9328 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9328 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9312, 80.0));\n                }\n                bool _9355;\n                if (_9321)\n                {\n                    _9355 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9355 = _9320;\n                }\n                float _9356;\n                if (_9355)\n                {\n                    _9356 = fa_mesh_fs_params[8].y * _9312;\n                }\n                else\n                {\n                    _9356 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9312, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9381 = _9317 <= 0.0;\n                bool _9388;\n                if (!_9381)\n                {\n                    _9388 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9388 = _9381;\n                }\n                float _9389;\n                if (_9388)\n                {\n                    _9389 = fa_mesh_fs_params[8].y * _9317;\n                }\n                else\n                {\n                    _9389 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9317, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9416;\n                if (abs(_9307) < 0.001000000047497451305389404296875)\n                {\n                    _9416 = _9328;\n                }\n                else\n                {\n                    _9416 = (_9389 - _9356) / _9307;\n                }\n                tau += (_9257 * max(_9416, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9452 = 1.0 - fa_tr_blend;\n        result /= vec3(_9452);\n        _9505 *= _9452;\n    }\n    fa_frag_color = vec4(result, _9505);\n}\n\n",
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
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
            "inst_name": "_665",
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
            "inst_name": "_2327",
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
            "inst_name": "_7621",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4822[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1603 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    bool _1618;\n    if (!_1610)\n    {\n        _1618 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1618 = _1610;\n    }\n    bool _1625;\n    if (!_1618)\n    {\n        _1625 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1625 = _1618;\n    }\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1642 = vec4(world_pos, 1.0);\n    float _1648 = dot(fa_mesh_fs_params[16], _1642);\n    if (!(_1648 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1670 = vec2(dot(fa_mesh_fs_params[14], _1642), dot(fa_mesh_fs_params[15], _1642)) / vec2(_1648);\n    int _1674 = int(fa_mesh_fs_params[18].x);\n    int _1678 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1678) + clamp(int(floor(((_1670.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1678 - 1)) * _1674)) + clamp(int(floor(((_1670.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1674 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1754 = fa_cluster_texel(param);\n    return ivec2(int(_1754.x), int(_1754.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6456 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6459 = fwidth(_6456);\n    bool _6462 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6469;\n    if (!_6462)\n    {\n        _6469 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6469 = _6462;\n    }\n    if (_6469)\n    {\n        fa_rt_slope = min(1.5 * _6459, 0.100000001490116119384765625 * _6456);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6485 = fa_cluster_lookup(param);\n    fa_cl_slot = _6485.x;\n    fa_cl_local = _6485.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7673 = fa_linear_to_srgb(param);\n        c = _7673;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7681 = fa_srgb_to_linear(param_1);\n            c = _7681;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _548;\n    if (i.front_facing)\n    {\n        _548 = i.world_normal;\n    }\n    else\n    {\n        _548 = -i.world_normal;\n    }\n    vec3 _572 = normalize(i.world_tangent.xyz - (_548 * dot(_548, i.world_tangent.xyz)));\n    vec3 _599 = normalize(((_572 * m.x) + ((cross(_548, _572) * i.world_tangent.w) * m.y)) + (_548 * m.z));\n    vec3 _602;\n    if (i.front_facing)\n    {\n        _602 = _599;\n    }\n    else\n    {\n        _602 = -_599;\n    }\n    return _602;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7713 = fa_tex_fix(param_2, param_3);\n    vec4 _10084 = base_t;\n    _10084.x = _7713.x;\n    _10084.y = _7713.y;\n    _10084.z = _7713.z;\n    base_t = _10084;\n    vec4 _7727 = (_10084 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9834 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7761 = fa_tex_fix(param_6, param_7);\n        vec3 _7764 = (_7761 * 2.0) - vec3(1.0);\n        vec2 _7769 = _7764.xy * fa_mesh_fs_params[6].x;\n        vec3 _10092 = _7764;\n        _10092.x = _7769.x;\n        _10092.y = _7769.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10092;\n        _9834 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7799 = fa_tex_fix(param_12, param_13);\n    vec4 _10095 = mrt;\n    _10095.x = _7799.x;\n    _10095.y = _7799.y;\n    _10095.z = _7799.z;\n    mrt = _10095;\n    vec4 _7829 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7829.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7840 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7872 = fa_tex_fix(param_20, param_21);\n    float _9839 = fa_mesh_fs_params[20].x;\n    float _9840 = fa_mesh_fs_params[20].y;\n    float _9843 = fa_mesh_fs_params[20].z;\n    float _9842 = fa_mesh_fs_params[21].w;\n    float _9845 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9839 *= _7840.y;\n            _9840 *= _7840.z;\n            _9842 *= _7829.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9843 *= mrt.x;\n            _9845 *= mrt.w;\n        }\n    }\n    return Surface(_7727.xyz, _7727.w, _9834, clamp(fa_mesh_fs_params[5].x * _7799.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7799.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7840.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7872), _9839, _9840, fa_mesh_fs_params[21].xyz, _9842, _9843, fa_mesh_fs_params[20].w, _9845, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1834 = rect.zw - rect.xy;\n    vec2 _1838 = _1834 * atlas;\n    vec2 _1842 = ddx * _1838;\n    vec2 _1846 = ddy * _1838;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1834), clamp(0.5 * log2(max(max(dot(_1842, _1842), dot(_1846, _1846)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1879 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1886;\n    if (!_1879)\n    {\n        _1886 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1886 = _1879;\n    }\n    if (_1886)\n    {\n        return;\n    }\n    vec3 _1892 = dFdx(world_pos);\n    vec3 _1895 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1899 = fa_cluster_texel(param);\n    int _1903 = int(_1899.w);\n    if (_1903 < 1)\n    {\n        return;\n    }\n    int _1913 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1913;\n    vec4 _1917 = fa_light_texel(param_1);\n    vec2 _1920 = _1917.yz;\n    int _1924 = int(_1917.w);\n    int param_2 = _1913 + 1;\n    vec4 _1929 = fa_light_texel(param_2);\n    float _1930 = _1929.x;\n    int _1936 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1940 = int(_1899.z);\n    vec3 _2205;\n    for (int k = 0; k < _1903; k++)\n    {\n        int _1953 = _1940 + k;\n        int param_3 = _1924 + (_1953 >> 2);\n        int _1970 = (_1913 + 2) + (int(fa_light_texel(param_3)[_1953 & 3]) * 7);\n        int param_4 = _1970 + 6;\n        vec4 _1975 = fa_light_texel(param_4);\n        if (((int(_1975.w + 0.5) >> _1936) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1970;\n        vec4 _1990 = fa_light_texel(param_5);\n        int param_6 = _1970 + 1;\n        vec4 _1995 = fa_light_texel(param_6);\n        int param_7 = _1970 + 2;\n        vec4 _2000 = fa_light_texel(param_7);\n        vec3 _2003 = _1990.xyz;\n        float _2008 = dot(_2003, world_pos) + _1990.w;\n        vec3 _2010 = _1995.xyz;\n        float _2015 = dot(_2010, world_pos) + _1995.w;\n        vec3 _2017 = _2000.xyz;\n        float _2022 = dot(_2017, world_pos) + _2000.w;\n        bool _2027 = abs(_2008) > 0.5;\n        bool _2035;\n        if (!_2027)\n        {\n            _2035 = abs(_2015) > 0.5;\n        }\n        else\n        {\n            _2035 = _2027;\n        }\n        bool _2043;\n        if (!_2035)\n        {\n            _2043 = abs(_2022) > 0.5;\n        }\n        else\n        {\n            _2043 = _2035;\n        }\n        if (_2043)\n        {\n            continue;\n        }\n        float _2058 = clamp(dot(geo_normal, normalize(_2017)) * _1975.z, 0.0, 1.0);\n        if (_2058 <= 0.0)\n        {\n            continue;\n        }\n        float _2078 = (clamp((0.5 - abs(_2022)) * 10.0, 0.0, 1.0) * _2058) * _1975.x;\n        vec2 _2086 = vec2(_2008 + 0.5, 0.5 - _2015);\n        vec2 _2096 = vec2(dot(_2003, _1892), dot(_2010, _1892));\n        vec2 _2106 = vec2(dot(_2003, _1895), dot(_2010, _1895));\n        int param_8 = _1970 + 5;\n        vec4 _2111 = fa_light_texel(param_8);\n        int param_9 = _1970 + 3;\n        vec4 _2116 = fa_light_texel(param_9);\n        int param_10 = _1970 + 4;\n        vec4 _2121 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2111.xyz;\n        bool _2131 = _2116.z > _2116.x;\n        if (_2131)\n        {\n            vec4 param_11 = _2116;\n            vec2 param_12 = _2086;\n            vec2 param_13 = _1920;\n            vec2 param_14 = _2096;\n            vec2 param_15 = _2106;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1930 > 0.5) && (_1930 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2157 = fa_dc_to_linear(param_16);\n                vec4 _9922 = tx;\n                _9922.x = _2157.x;\n                _9922.y = _2157.y;\n                _9922.z = _2157.z;\n                tx = _9922;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2078 * tex_a) * _2111.w, 0.0, 1.0)));\n        if (_2121.z > _2121.x)\n        {\n            vec4 param_17 = _2121;\n            vec2 param_18 = _2086;\n            vec2 param_19 = _1920;\n            vec2 param_20 = _2096;\n            vec2 param_21 = _2106;\n            vec4 _2201 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1930 > 1.5)\n            {\n                vec3 param_22 = _2201.xyz;\n                vec3 _2211 = fa_dc_to_srgb(param_22);\n                _2205 = _2211;\n            }\n            else\n            {\n                _2205 = _2201.xyz;\n            }\n            vec3 _2220 = (_2205 * 2.0) - vec3(1.0);\n            vec2 _2225 = _2220.xy * _1975.y;\n            vec3 _2247 = (normalize(_2003) * _2225.x) + (normalize(_2010) * _2225.y);\n            vec3 _2250 = normalize(normal);\n            normal = normalize(mix(_2250, normalize((_2250 * max(_2220.z, 0.0500000007450580596923828125)) + (_2247 - (_2250 * dot(_2250, _2247)))), vec3(clamp(_2078 * (_2131 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4747 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4755 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4758 = int(_4747);\n    int _4761 = int(_4755);\n    float _4771 = _4755 - float(_4761);\n    int _4826 = (_4758 * 9) + _4761;\n    int _4846 = ((_4758 + 1) * 9) + _4761;\n    return mix(mix(_4822[_4826], _4822[_4826 + 1], _4771), mix(_4822[_4846], _4822[_4846 + 1], _4771), _4747 - float(_4758));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9757 = false;\n    float _9758 = 1.0;\n    float _9759 = 1.0;\n    float _9760 = 1.0;\n    float _9761 = 0.0;\n    float _9762 = 0.0;\n    float _9763 = 0.0;\n    float _9764 = 0.0;\n    float _9766 = 1.0;\n    bool _9767 = false;\n    vec3 _9768 = vec3(0.0);\n    float _9769 = 1.0;\n    float _9770 = 1.0;\n    float _9771 = 1.0;\n    float _9772 = 0.0;\n    float _9773 = 0.0;\n    vec3 _9774 = vec3(1.0, 0.0, 0.0);\n    vec3 _9775 = vec3(0.0, 0.0, 1.0);\n    float _9776 = 1.0;\n    float _9777 = 1.0;\n    float _4897 = clamp(s.specular, 0.0, 1.0);\n    float _4901 = clamp(s.ior, 1.0, 3.0);\n    bool _4906 = (_4897 != 1.0) || (_4901 != 1.5);\n    bool _4915;\n    if (!_4906)\n    {\n        _4915 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4915 = _4906;\n    }\n    if (_4915)\n    {\n        float _4923 = (_4901 - 1.0) / (_4901 + 1.0);\n        f0 = mix(min(vec3(_4923 * _4923) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4897, s.albedo, vec3(metallic));\n        _9758 = mix(_4897, 1.0, metallic);\n        _9757 = true;\n    }\n    float _4950 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4950 > 0.0)\n    {\n        float _4958 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9761 = _4950;\n        _9762 = _4958;\n        float _4965 = _4958 * _4958;\n        _9763 = _4965;\n        _9764 = _4965 * _4965;\n        float _4977 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9766 = _4977;\n        _9759 = 1.0 - (_4950 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4977, 0.0, 1.0), 5.0))));\n        _9757 = true;\n    }\n    vec3 _4996 = max(s.sheen_color, vec3(0.0));\n    float _5005 = max(_4996.x, max(_4996.y, _4996.z));\n    if (_5005 > 0.0)\n    {\n        float _5013 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9767 = true;\n        _9768 = _4996;\n        _9769 = _5013;\n        _9770 = _5013 * _5013;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5013;\n        float _5030 = fa_sheen_albedo(param, param_1);\n        _9772 = _5030;\n        _9771 = 1.0 - min(_5005 * _5030, 1.0);\n        _9757 = true;\n    }\n    _9760 = _9759 * _9771;\n    float _5049 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5049 != 0.0)\n    {\n        vec3 _5064 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5064;\n        if (dot(_5064, _5064) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5076 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5076.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5076.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5076.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5080 = t;\n        vec3 _5081 = normalize(_5080);\n        t = _5081;\n        vec3 _5106 = normalize((_5081 * cos(s.anisotropy_rotation)) + ((cross(n, _5081) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9774 = _5106;\n        _9775 = cross(n, _5106);\n        float _5116 = roughness * roughness;\n        float _5122 = mix(_5116, 1.0, _5049 * _5049);\n        bool _5124 = _5049 > 0.0;\n        _9776 = _5124 ? _5122 : _5116;\n        _9777 = _5124 ? _5116 : _5122;\n        _9773 = _5049;\n        _9757 = true;\n    }\n    return FaLayers(_9757, _9758, _9759, _9760, _9761, _9762, _9763, _9764, i.world_normal, _9766, _9767, _9768, _9769, _9770, _9771, _9772, _9773, _9774, _9775, _9776, _9777);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3918 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3918;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4529 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4534 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4529 > 0.0005000000237487256526947021484375)\n    {\n        if (_4534)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4529;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4529;\n        }\n    }\n    bool _4584 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4584)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4615 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4615)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4534 || _4584) || _4615)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3938 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3941 = _3938.x;\n    float _3943 = _3938.z;\n    vec2 e = vec2(_3941, _3943);\n    if (_3938.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3943)) * ((_3941 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3941)) * ((_3943 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7982 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7987 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7992 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7997 = fa_light_texel(param_3);\n    bool _8000 = _7997.z < 0.5;\n    bool _8008;\n    if (!_8000)\n    {\n        _8008 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8008 = _8000;\n    }\n    if (_8008)\n    {\n        return vec3(0.0);\n    }\n    float _8015 = max(_7982.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8018 = _7987.xyz;\n    vec3 _8022 = _7982.xyz;\n    vec3 _8026 = (fa_world_pos - _8022) / vec3(_8015);\n    vec3 _8035 = min(_8026 + vec3(0.5), (_8018 - vec3(0.5)) - _8026);\n    float _8044 = min(_8035.x, min(_8035.y, _8035.z));\n    if (!(_8044 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8059 = _8018 - vec3(1.0);\n    vec3 _8060 = clamp(_8026, vec3(0.0), _8059);\n    vec3 _8068 = min(floor(_8060), max(_8018 - vec3(2.0), vec3(0.0)));\n    vec3 _8072 = _8060 - _8068;\n    vec3 _8083 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8015));\n    int _8088 = int(_7992.y + 0.5);\n    float _8093 = 0.3257350027561187744140625 * n.y;\n    float _8097 = 0.3257350027561187744140625 * n.z;\n    float _8101 = 0.3257350027561187744140625 * n.x;\n    float _8108 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8115 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8124 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8131 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8144 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8151 = 8 + int(_7997.w);\n    float _8178;\n    float _8191;\n    float _8205;\n    for (int k = 0; k < _8151; k++)\n    {\n        float _8164 = float(k & 1);\n        float _8168 = float((k >> 1) & 1);\n        float _8172 = float((k >> 2) & 1);\n        if (_8164 > 0.5)\n        {\n            _8178 = _8072.x;\n        }\n        else\n        {\n            _8178 = 1.0 - _8072.x;\n        }\n        if (_8168 > 0.5)\n        {\n            _8191 = _8072.y;\n        }\n        else\n        {\n            _8191 = 1.0 - _8072.y;\n        }\n        if (_8172 > 0.5)\n        {\n            _8205 = _8072.z;\n        }\n        else\n        {\n            _8205 = 1.0 - _8072.z;\n        }\n        float _8215 = (_8178 * _8191) * _8205;\n        if (!(_8215 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8228 = min(_8068 + vec3(_8164, _8168, _8172), _8059);\n        int _8248 = int(((_7992.x + _8228.x) + (_7987.x * (_8228.y + (_7987.y * _8228.z)))) + 0.5);\n        vec2 _8263 = vec2(float(_8248 % _8088) * 10.0, 1024.0 + (float(_8248 / _8088) * 11.0));\n        vec2 param_4 = _8263 + vec2(9.5, 10.5);\n        vec4 _8271 = fa_gi_fetch(param_4);\n        bool _8274 = _8271.y < 0.5;\n        bool _8283;\n        if (!_8274)\n        {\n            _8283 = _8271.x > _7997.y;\n        }\n        else\n        {\n            _8283 = _8274;\n        }\n        if (_8283)\n        {\n            continue;\n        }\n        vec3 _8295 = _8083 - (_8022 + (_8228 * _8015));\n        float _8298 = length(_8295);\n        vec3 _8304 = _8295 / vec3(max(_8298, 9.9999997473787516355514526367188e-05));\n        float _8314 = max(9.9999997473787516355514526367188e-05, (dot(-_8304, n) + 1.0) * 0.5);\n        float w = _8215 * (_8314 * _8314);\n        vec3 param_5 = _8304;\n        vec2 param_6 = (_8263 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8333 = fa_gi_fetch(param_6);\n        float _8340 = _8298 / max(_7992.z, 9.9999997473787516355514526367188e-05);\n        float _8343 = _8333.x;\n        if (_8340 > _8343)\n        {\n            float _8356 = max(_8333.y - (_8343 * _8343), 0.0);\n            float _8361 = _8340 - _8343;\n            float _8370 = _8356 / max(_8356 + (_8361 * _8361), 9.9999999600419720025001879548654e-13);\n            w *= ((_8370 * _8370) * _8370);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8263 + vec2(0.5, 10.5);\n        vec2 param_8 = _8263 + vec2(1.5, 10.5);\n        vec2 param_9 = _8263 + vec2(2.5, 10.5);\n        vec2 param_10 = _8263 + vec2(3.5, 10.5);\n        vec2 param_11 = _8263 + vec2(4.5, 10.5);\n        vec2 param_12 = _8263 + vec2(5.5, 10.5);\n        vec2 param_13 = _8263 + vec2(6.5, 10.5);\n        vec2 param_14 = _8263 + vec2(7.5, 10.5);\n        vec2 param_15 = _8263 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8093)) + (fa_gi_fetch(param_9).xyz * _8097)) + (fa_gi_fetch(param_10).xyz * _8101)) + (fa_gi_fetch(param_11).xyz * _8108)) + (fa_gi_fetch(param_12).xyz * _8115)) + (fa_gi_fetch(param_13).xyz * _8124)) + (fa_gi_fetch(param_14).xyz * _8131)) + (fa_gi_fetch(param_15).xyz * _8144)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8044 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8495;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8495 = _7997.x;\n    }\n    else\n    {\n        _8495 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7992.w * _8495);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8524 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8529 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8529) && (k < 8); k++)\n    {\n        int param = _8524 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8519;\n        vec3 _8554 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8559 = param_3 * left;\n        acc += (_8554 * _8559);\n        left -= _8559;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8588 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8588;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8630 = vec4(fa_world_pos, 1.0);\n        vec2 _8649 = vec2(dot(fa_mesh_fs_params[26], _8630), dot(fa_mesh_fs_params[27], _8630)) / vec2(max(dot(fa_mesh_fs_params[28], _8630), 9.9999997473787516355514526367188e-05));\n        float _8658;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8658 = (_8649.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8658 = 0.5 - (_8649.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8649.x * 0.5) + 0.5, _8658) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6426;\n    if (fa_lm.z > 0.5)\n    {\n        _6426 = 0.0;\n    }\n    else\n    {\n        _6426 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6437 = _6426 < 1.0;\n    bool _6443;\n    if (_6437)\n    {\n        int param = li;\n        _6443 = fa_light_baked(param);\n    }\n    else\n    {\n        _6443 = _6437;\n    }\n    return _6443 ? _6426 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _852 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _865 = (c - (ru * hx)) - p;\n        vec3 _871 = ru * (2.0 * hx);\n        float _877 = max(dot(_871, _871), 9.9999999392252902907785028219223e-09);\n        float _881 = dot(_865, _871);\n        float t = clamp((-_881) / _877, 0.0, 1.0);\n        if (_852)\n        {\n            float _896 = dot(r, _871);\n            float _902 = _877 - (_896 * _896);\n            if (abs(_902) > (9.9999997473787516355514526367188e-06 * _877))\n            {\n                t = clamp(((dot(r, _865) * _896) - _881) / _902, 0.0, 1.0);\n            }\n        }\n        return (p + _865) + (_871 * t);\n    }\n    vec3 q = p;\n    float _934 = dot(r, axis);\n    bool _942;\n    if (_852)\n    {\n        _942 = abs(_934) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _942 = _852;\n    }\n    if (_942)\n    {\n        float _952 = dot(c - p, axis) / _934;\n        if (_952 > 0.0)\n        {\n            q = p + (r * _952);\n        }\n    }\n    vec3 _965 = q - c;\n    vec2 xy = vec2(dot(_965, ru), dot(_965, uu));\n    if (shape > 0.5)\n    {\n        float _980 = length(xy);\n        if (_980 > hx)\n        {\n            xy *= (hx / _980);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _614 = abs(d);\n    float _616 = _614.x;\n    float _618 = _614.y;\n    bool _619 = _616 >= _618;\n    bool _627;\n    if (_619)\n    {\n        _627 = _616 >= _614.z;\n    }\n    else\n    {\n        _627 = _619;\n    }\n    int _628;\n    if (_627)\n    {\n        _628 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _642;\n        if (_618 >= _614.z)\n        {\n            _642 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _642 = (d.z > 0.0) ? 4 : 5;\n        }\n        _628 = _642;\n    }\n    return _628;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _772 = dot(d, right);\n    float _776 = dot(d, up);\n    float _787;\n    if (((_772 * _772) + (_776 * _776)) > 1.0000000133514319600180897396058e-10)\n    {\n        _787 = atan(_776, _772) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _787 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_787 - floor(_787)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1018 = fa_light_base(param);\n    bool _1022 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1018;\n    vec4 _1026 = fa_light_texel(param_1);\n    int param_2 = _1018 + 1;\n    vec4 _1031 = fa_light_texel(param_2);\n    float _1034 = _1031.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1046 = _1022 && (_1034 > 2.5);\n    fa_light_is_area = _1046;\n    bool _1048 = _1034 < 0.5;\n    vec3 l;\n    if (_1048)\n    {\n        l = normalize(_1026.xyz);\n        if (_1022)\n        {\n            int param_3 = _1018 + 6;\n            vec4 _1062 = fa_light_texel(param_3);\n            if (_1062.z > 0.5)\n            {\n                int param_4 = _1018 + 4;\n                vec4 _1072 = fa_light_texel(param_4);\n                int param_5 = _1018 + 5;\n                vec4 _1077 = fa_light_texel(param_5);\n                vec2 param_6 = _1062.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1072.xyz) * _1072.w, (-dot(world_pos, _1077.xyz)) * _1077.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1107 = _1026.xyz;\n        vec3 _1109 = _1107 - world_pos;\n        vec3 to_light = _1109;\n        float _1112 = length(_1109);\n        float reach = _1112;\n        bool front = true;\n        if (_1046)\n        {\n            int param_8 = _1018 + 7;\n            reach = max(_1112 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1018 + 4;\n            vec4 _1136 = fa_light_texel(param_9);\n            int param_10 = _1018 + 5;\n            vec4 _1141 = fa_light_texel(param_10);\n            int param_11 = _1018 + 6;\n            vec4 _1146 = fa_light_texel(param_11);\n            float _1147 = _1146.w;\n            int param_12 = _1018 + 2;\n            vec3 _1154 = normalize(fa_light_texel(param_12).xyz);\n            bool _1156 = _1147 > 1.5;\n            bool _1164;\n            if (!_1156)\n            {\n                _1164 = dot(_1154, to_light) < 0.0;\n            }\n            else\n            {\n                _1164 = _1156;\n            }\n            front = _1164;\n            vec3 r = vec3(0.0);\n            vec3 _1173 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1177 = dot(n, n) > 0.5;\n            bool _1185;\n            if (_1177)\n            {\n                _1185 = dot(_1173, _1173) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1185 = _1177;\n            }\n            if (_1185)\n            {\n                r = reflect(-normalize(_1173), normalize(n));\n            }\n            vec3 param_13 = _1107;\n            vec3 param_14 = _1154;\n            vec3 param_15 = _1136.xyz;\n            vec3 param_16 = _1141.xyz;\n            float param_17 = _1136.w;\n            float param_18 = _1141.w;\n            float param_19 = _1147;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1221 = length(to_light);\n        dist = _1221;\n        l = to_light / vec3(max(_1221, 9.9999997473787516355514526367188e-05));\n        float _1235 = reach / max(_1026.w, 0.001000000047497451305389404296875);\n        float _1241 = clamp(1.0 - (_1235 * _1235), 0.0, 1.0);\n        float _1243;\n        if (front)\n        {\n            _1243 = _1241 * _1241;\n        }\n        else\n        {\n            _1243 = 0.0;\n        }\n        atten = _1243;\n        bool _1254 = _1034 < 2.5;\n        if ((_1034 > 1.5) && _1254)\n        {\n            int param_22 = _1018 + 2;\n            vec4 _1262 = fa_light_texel(param_22);\n            float _1272 = _1262.w;\n            int param_23 = _1018 + 3;\n            vec4 _1277 = fa_light_texel(param_23);\n            float _1278 = _1277.x;\n            float cos_inner = _1278;\n            if (_1278 > 1.5)\n            {\n                cos_inner = mix(_1272, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1272, cos_inner, dot(-l, normalize(_1262.xyz)));\n        }\n        if (_1022 && (_1034 < 1.5))\n        {\n            int param_24 = _1018 + 6;\n            vec4 _1302 = fa_light_texel(param_24);\n            if (_1302.z > 0.5)\n            {\n                vec3 _1310 = -to_light;\n                int param_25 = _1018 + 4;\n                int param_26 = _1018 + 5;\n                vec3 _1324 = fa_light_texel(param_25).xyz;\n                vec3 _1328 = fa_light_texel(param_26).xyz;\n                vec3 _1337 = vec3(dot(_1310, _1324), dot(_1310, _1328), dot(_1310, cross(_1324, _1328)));\n                vec3 param_27 = _1337;\n                int _1341 = fa_cube_face(param_27);\n                int param_28 = _1341;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1368 = vec2(dot(_1337, cross(param_29, param_30)), dot(_1337, param_30)) / vec2(max(dot(_1337, param_29), 9.9999997473787516355514526367188e-05));\n                int _1372 = _1341 / 3;\n                vec2 param_31 = _1302.xy + (vec2(float(_1341 - (_1372 * 3)), float(_1372)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1368.x), 0.5 - (0.5 * _1368.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1018 + 7;\n            vec4 _1402 = fa_light_texel(param_33);\n            if (_1402.z > 0.5)\n            {\n                int param_34 = _1018 + 2;\n                int param_35 = _1018 + 4;\n                int param_36 = _1018 + 5;\n                vec2 param_37 = _1402.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1022 && _1254)\n            {\n                int param_42 = _1018 + 6;\n                vec4 _1449 = fa_light_texel(param_42);\n                int param_43 = _1018 + 7;\n                vec4 _1454 = fa_light_texel(param_43);\n                bool _1457 = _1449.z > 0.5;\n                bool _1464;\n                if (!_1457)\n                {\n                    _1464 = _1454.z > 0.5;\n                }\n                else\n                {\n                    _1464 = _1457;\n                }\n                if (_1464)\n                {\n                    int param_44 = _1018 + 2;\n                    vec4 _1471 = fa_light_texel(param_44);\n                    vec3 _1475 = normalize(_1471.xyz);\n                    int param_45 = _1018 + 4;\n                    vec4 _1480 = fa_light_texel(param_45);\n                    int param_46 = _1018 + 5;\n                    vec4 _1485 = fa_light_texel(param_46);\n                    if (_1457)\n                    {\n                        vec3 _1493 = -to_light;\n                        float _1500 = _1471.w;\n                        float _1516 = 0.5 / max(dot(_1493, _1475) * (sqrt(max(1.0 - (_1500 * _1500), 0.0)) / max(_1500, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1449.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1493, _1480.xyz) * _1516), 0.5 - (dot(_1493, _1485.xyz) * _1516));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1454.z > 0.5)\n                    {\n                        vec2 param_49 = _1454.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1475;\n                        vec3 param_52 = _1480.xyz;\n                        vec3 param_53 = _1485.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9745 = _1031.xyz * atten;\n    if (_1022)\n    {\n        _9745 *= fa_light_tint;\n    }\n    int _1585;\n    if (_1048)\n    {\n        _1585 = 0;\n    }\n    else\n    {\n        _1585 = ((_1034 > 1.5) && (_1034 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9745, atten, 1.0, dist, _1585);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2317;\n    if (i == 0)\n    {\n        _2317 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2333;\n        if (i == 1)\n        {\n            _2333 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2341;\n            if (i == 2)\n            {\n                _2341 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2341 = fa_shadows[24].w;\n            }\n            _2333 = _2341;\n        }\n        _2317 = _2333;\n    }\n    return _2317;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2374 = fa_shadow_depth(param, param_1);\n    float _2378;\n    if (conv.x < 0.5)\n    {\n        _2378 = _2374;\n    }\n    else\n    {\n        _2378 = (conv.y * conv.z) / (conv.z - (_2374 * (conv.z - conv.y)));\n    }\n    return _2378;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2424 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2430 = vec2(cos(_2424), sin(_2424));\n    vec2 dir = _2430;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2439;\n        if (k < 0.0)\n        {\n            _2439 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2439 = k;\n        }\n        float _2458 = clamp((_2439 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2477 = sqrt((float(i) + 0.5) * 0.0625) * _2458;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2477));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2491 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2491 < (zr - (_2477 * plane)))\n            {\n                sum += _2491;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2519 = sum / cnt;\n        float _2529;\n        if (k < 0.0)\n        {\n            _2529 = (-k) / max(_2519, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2529 = k;\n        }\n        radius = clamp(((max(zr - _2519, 0.0) * unit) * _2529) / texel_m, 1.5, 16.0);\n        dir = _2430;\n    }\n    float lit = 0.0;\n    int _2555 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2555; i_1++)\n    {\n        float _2574 = sqrt((float(i_1) + 0.5) / float(_2555)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2574));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2574 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2555);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2620 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2625 = clamp(dot(n, l), 0.0, 1.0);\n    float _2631 = sqrt(1.0 - (_2625 * _2625));\n    float _2639 = min(_2631 / max(_2625, 0.20000000298023223876953125), 4.0);\n    float _2644;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2644 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2644 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2669 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2644 * _2631)), 1.0);\n    float _2676 = _2669.x;\n    bool _2679 = _2676 < fa_shadows[ci * 1 + 16].x;\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2676 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2669.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2706;\n    if (!_2697)\n    {\n        _2706 = _2669.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2706 = _2697;\n    }\n    bool _2713;\n    if (!_2706)\n    {\n        _2713 = _2669.z > 1.0;\n    }\n    else\n    {\n        _2713 = _2706;\n    }\n    if (_2713)\n    {\n        return -1.0;\n    }\n    float _2721;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2721 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2721 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2669.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2669.z - ((_2721 * (1.0 + (0.5 * _2639))) / _2620);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2620;\n    float param_5 = _2620 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2639, 3.0)) * 0.5) / _2620;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3099 = int(fa_shadows[25].x + 0.5);\n    if (_3099 < 1)\n    {\n        return 1.0;\n    }\n    float _3114 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3099 - 1;\n    if (_3114 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3126 = _3099 > 1;\n    bool _3133;\n    if (_3126)\n    {\n        _3133 = _3114 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3133 = _3126;\n    }\n    if (_3133)\n    {\n        ci = 1;\n    }\n    bool _3137 = _3099 > 2;\n    bool _3144;\n    if (_3137)\n    {\n        _3144 = _3114 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3144 = _3137;\n    }\n    if (_3144)\n    {\n        ci = 2;\n    }\n    bool _3148 = _3099 > 3;\n    bool _3155;\n    if (_3148)\n    {\n        _3155 = _3114 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3155 = _3148;\n    }\n    if (_3155)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3166 = min(_3099, 4);\n    float _3207;\n    for (int c = ci; c < _3166; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3186 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3186;\n            break;\n        }\n        if (_3186 < 0.0)\n        {\n            continue;\n        }\n        s = _3186;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3207 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3207 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3226 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3207, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3114 - (fa_shadow_split_at(param_7) - _3226)) / _3226, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3258;\n        if ((ci + 1) < _3099)\n        {\n            _3258 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3258 = 1.0;\n        }\n        s = mix(s, _3258, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3363 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3369;\n    if (_3363)\n    {\n        _3369 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3369 = _3363;\n    }\n    if (_3369)\n    {\n        float _3383 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3391 = vec4(fa_world_pos, 1.0);\n        float _3397 = dot(fa_mesh_fs_params[28], _3391);\n        if (_3397 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3416 = vec2(dot(fa_mesh_fs_params[26], _3391), dot(fa_mesh_fs_params[27], _3391)) / vec2(_3397);\n            float _3421 = (_3416.x * 0.5) + 0.5;\n            float _3425;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3425 = (_3416.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3425 = 0.5 - (_3416.y * 0.5);\n            }\n            bool _3441 = _3421 >= 0.0;\n            bool _3447;\n            if (_3441)\n            {\n                _3447 = _3421 < 1.0;\n            }\n            else\n            {\n                _3447 = _3441;\n            }\n            bool _3453;\n            if (_3447)\n            {\n                _3453 = _3425 >= 0.0;\n            }\n            else\n            {\n                _3453 = _3447;\n            }\n            bool _3459;\n            if (_3453)\n            {\n                _3459 = _3425 < 1.0;\n            }\n            else\n            {\n                _3459 = _3453;\n            }\n            if (_3459)\n            {\n                vec4 _3485 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3421, _3425) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3488 = _3485.w > 0.5;\n                bool _3504;\n                if (_3488)\n                {\n                    _3504 = abs(_3383 - _3485.x) <= (((0.00200000009499490261077880859375 * _3383) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3504 = _3488;\n                }\n                if (_3504)\n                {\n                    float _3510;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3510 = min(_3485.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3510 = _3485.y;\n                    }\n                    return _3510;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2779 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2786;\n    if (!_2779)\n    {\n        _2786 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2786 = _2779;\n    }\n    if (_2786)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2799 = fa_light_texel(param);\n    float _2800 = _2799.x;\n    if (_2800 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2809 = int(_2800 + 0.5);\n    int param_1 = _2809;\n    vec4 _2813 = fa_light_texel(param_1);\n    int param_2 = _2809 + 1;\n    vec4 _2818 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2821 = _2813.y;\n    if (_2821 > 0.0)\n    {\n        float _2838 = 1.0 - smoothstep(0.75 * _2821, _2821, length(world - fa_shadows[27].xyz));\n        fade = _2838;\n        if (_2838 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2813.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2862 = (_2809 + 2) + (face * 6);\n    int param_4 = _2862;\n    int param_5 = _2862 + 1;\n    int param_6 = _2862 + 3;\n    vec4 _2876 = fa_light_texel(param_6);\n    int param_7 = _2862 + 4;\n    vec4 _2881 = fa_light_texel(param_7);\n    int param_8 = _2862 + 5;\n    vec4 _2886 = fa_light_texel(param_8);\n    float _2898 = _2886.x * max(dot(_2876, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2903 = clamp(dot(n, l), 0.0, 1.0);\n    float _2926 = clamp(dot(n, _2876.xyz), -1.0, 1.0);\n    float _2945 = min(sqrt(1.0 - (_2926 * _2926)) / max(abs(dot(n, world - lpos)) / max(dot(_2876, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2948 = _2818.y;\n    float _2950;\n    if (_2948 > 0.0)\n    {\n        _2950 = _2948;\n    }\n    else\n    {\n        _2950 = 1.5 * _2898;\n    }\n    vec4 _2970 = vec4(world + (n * (_2950 * sqrt(1.0 - (_2903 * _2903)))), 1.0);\n    float _2974 = dot(_2876, _2970);\n    float _2977 = _2886.y;\n    if (_2974 < _2977)\n    {\n        return 1.0;\n    }\n    vec2 _2992 = vec2(dot(fa_light_texel(param_4), _2970), dot(fa_light_texel(param_5), _2970)) / vec2(_2974);\n    float _2994 = _2992.x;\n    bool _2997 = _2994 < _2881.x;\n    bool _3006;\n    if (!_2997)\n    {\n        _3006 = _2994 > _2881.z;\n    }\n    else\n    {\n        _3006 = _2997;\n    }\n    bool _3015;\n    if (!_3006)\n    {\n        _3015 = _2992.y < _2881.y;\n    }\n    else\n    {\n        _3015 = _3006;\n    }\n    bool _3024;\n    if (!_3015)\n    {\n        _3024 = _2992.y > _2881.w;\n    }\n    else\n    {\n        _3024 = _3015;\n    }\n    if (_3024)\n    {\n        return 1.0;\n    }\n    float _3030 = _2818.x;\n    float _3032;\n    if (_3030 > 0.0)\n    {\n        _3032 = _3030;\n    }\n    else\n    {\n        _3032 = 1.5 * _2898;\n    }\n    vec2 param_9 = _2992;\n    vec4 param_10 = _2881;\n    float param_11 = _2974 - (_3032 * (1.0 + (0.5 * _2945)));\n    float param_12 = _2898;\n    float param_13 = 1.0;\n    float param_14 = _2886.z * 0.25;\n    float param_15 = (_2898 * min(_2945, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2977, _2886.z);\n    int param_17 = int(_2813.z + 0.5);\n    float param_18 = _2813.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3539 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3545;\n    if (_3539)\n    {\n        _3545 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3545 = _3539;\n    }\n    bool _3551;\n    if (_3545)\n    {\n        _3551 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3551 = _3545;\n    }\n    if (_3551)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3563 = fa_light_texel(param);\n        float _3564 = _3563.z;\n        if (_3564 > 0.5)\n        {\n            float _3577 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3583 = ((0.00200000009499490261077880859375 * _3577) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3589 = vec4(world, 1.0);\n            float _3594 = dot(fa_mesh_fs_params[28], _3589);\n            if (_3594 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3611 = vec2(dot(fa_mesh_fs_params[26], _3589), dot(fa_mesh_fs_params[27], _3589)) / vec2(_3594);\n                float _3616 = (_3611.x * 0.5) + 0.5;\n                float _3620;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3620 = (_3611.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3620 = 0.5 - (_3611.y * 0.5);\n                }\n                bool _3636 = _3616 >= 0.0;\n                bool _3642;\n                if (_3636)\n                {\n                    _3642 = _3616 < 1.0;\n                }\n                else\n                {\n                    _3642 = _3636;\n                }\n                bool _3648;\n                if (_3642)\n                {\n                    _3648 = _3620 >= 0.0;\n                }\n                else\n                {\n                    _3648 = _3642;\n                }\n                bool _3654;\n                if (_3648)\n                {\n                    _3654 = _3620 < 1.0;\n                }\n                else\n                {\n                    _3654 = _3648;\n                }\n                if (_3654)\n                {\n                    ivec2 _3671 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3672 = clamp(ivec2(vec2(_3616, _3620) * fa_mesh_fs_params[24].zw), ivec2(0), _3671);\n                    float _3676;\n                    if (_3564 < 1.5)\n                    {\n                        _3676 = 1.0;\n                    }\n                    else\n                    {\n                        _3676 = (_3564 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3698;\n                    int _3704;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3698 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3704 = k - 1;\n                            }\n                            else\n                            {\n                                _3704 = k;\n                            }\n                            _3698 = _3704;\n                        }\n                        vec4 _3733 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3672 + ivec2((_3698 % 3) - 1, (_3698 / 3) - 1), ivec2(0), _3671), 0);\n                        bool _3736 = _3733.w > 0.5;\n                        bool _3746;\n                        if (_3736)\n                        {\n                            _3746 = abs(_3577 - _3733.x) <= _3583;\n                        }\n                        else\n                        {\n                            _3746 = _3736;\n                        }\n                        if (_3746)\n                        {\n                            best = min(best, mod(floor(_3733.z / _3676), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3773;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3773 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3773 = best;\n                        }\n                        return _3773;\n                    }\n                }\n            }\n            float _3796;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3796 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3796 = 1.0;\n            }\n            return _3796;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5640 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5647;\n    if (!_5640)\n    {\n        _5647 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5647 = _5640;\n    }\n    if (_5647)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5660 = fa_light_texel(param);\n    float _5661 = _5660.y;\n    float len = _5661;\n    if (_5661 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5673 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5682 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5673);\n    if (_5682 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5688 = len;\n    float _5691 = min(_5688, 0.89999997615814208984375 * dist);\n    len = _5691;\n    float _5696 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5673);\n    float _5701 = _5696 + (0.5 * _5691);\n    vec3 _5707 = world + (gn * _5696);\n    float _5709 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5770;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5724 = (float(k) + _5709) * 0.083333335816860198974609375;\n        vec3 _5732 = _5707 + (l * (_5724 * len));\n        vec4 _5738 = vec4(_5732, 1.0);\n        float _5743 = dot(fa_mesh_fs_params[28], _5738);\n        if (_5743 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5761 = vec2(dot(fa_mesh_fs_params[26], _5738), dot(fa_mesh_fs_params[27], _5738)) / vec2(_5743);\n        float _5765 = _5761.x * 0.5;\n        float _5766 = _5765 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5770 = (_5761.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5770 = 0.5 - (_5761.y * 0.5);\n        }\n        bool _5786 = _5766 < 0.0;\n        bool _5793;\n        if (!_5786)\n        {\n            _5793 = _5766 >= 1.0;\n        }\n        else\n        {\n            _5793 = _5786;\n        }\n        bool _5800;\n        if (!_5793)\n        {\n            _5800 = _5770 < 0.0;\n        }\n        else\n        {\n            _5800 = _5793;\n        }\n        bool _5807;\n        if (!_5800)\n        {\n            _5807 = _5770 >= 1.0;\n        }\n        else\n        {\n            _5807 = _5800;\n        }\n        if (_5807)\n        {\n            break;\n        }\n        vec4 _5831 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5766, _5770) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5831.w < 0.5)\n        {\n            continue;\n        }\n        float _5849 = (dot(fa_mesh_fs_params[29].xyz, _5732) + fa_mesh_fs_params[29].w) - _5831.x;\n        if ((_5849 > _5696) && (_5849 < _5701))\n        {\n            occ = max(occ, (1.0 - (_5724 * _5724)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5766, 0.5 - _5765), min(_5770, 1.0 - _5770))));\n        }\n    }\n    return 1.0 - (occ * _5682);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6511 = fa_baked_keep(param);\n    if (_6511 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6537 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9814 = _6537.color;\n    float _9815 = _6537.attenuation;\n    float _9816 = _6537.shadow;\n    bool _6540 = _6537.type == 0;\n    if (_6540 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6537.direction;\n        float _6551 = fa_shadow_factor(param_5, param_6);\n        _9816 = _6551;\n        _9814 *= _6551;\n    }\n    else\n    {\n        bool _6562 = _6537.type != 0;\n        bool _6568;\n        if (_6562)\n        {\n            _6568 = _9815 > 0.0;\n        }\n        else\n        {\n            _6568 = _6562;\n        }\n        if (_6568)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6537.direction;\n            float _6587 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9816 = _6587;\n            _9814 *= _6587;\n        }\n    }\n    bool _6597 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6603;\n    if (_6597)\n    {\n        _6603 = _9815 > 0.0;\n    }\n    else\n    {\n        _6603 = _6597;\n    }\n    if (_6603)\n    {\n        float _6610;\n        if (_6540)\n        {\n            _6610 = 1000000000.0;\n        }\n        else\n        {\n            _6610 = _6537._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6537.direction;\n        float param_18 = _6610;\n        float _6628 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9816 *= _6628;\n        _9814 *= _6628;\n    }\n    float _6641 = _9815;\n    float _6642 = _6641 * _6511;\n    _9815 = _6642;\n    vec3 _6646 = _9814;\n    vec3 _6647 = _6646 * _6511;\n    _9814 = _6647;\n    return LightSample(_6537.direction, _6647, _6642, _9816, _6537._distance, _6537.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6681 = v - (n * dot(v, n));\n    vec3 t = _6681;\n    float _6685 = dot(_6681, _6681);\n    float l2 = _6685;\n    if (_6685 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6695;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6695 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6695 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6695;\n        l2 = dot(_6695, _6695);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7082;\n    if ((j == 0) || (j == 7))\n    {\n        _7082 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7092;\n        if ((j == 3) || (j == 4))\n        {\n            _7092 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7092 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7082 = _7092;\n    }\n    float _7113;\n    if ((j == 1) || (j == 2))\n    {\n        _7113 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7122;\n        if ((j == 5) || (j == 6))\n        {\n            _7122 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7122 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7113 = _7122;\n    }\n    return (pc + (ex * _7082)) + (ey * _7113);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6730 = dot(a, a);\n    float _6734 = dot(b, b);\n    if ((_6730 < 1.0000000195414813782625560981111e-24) || (_6734 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6748 = a * inversesqrt(_6730);\n    vec3 _6753 = b * inversesqrt(_6734);\n    float _6757 = dot(_6748, _6753);\n    float _6760 = abs(_6757);\n    float g = (((((((((((0.0416471660137176513671875 * _6760) - 0.1924748718738555908203125) * _6760) + 0.4179156124591827392578125) * _6760) - 0.616057217121124267578125) * _6760) + 0.777722418308258056640625) * _6760) - 0.999542415142059326171875) * _6760) + 1.570791721343994140625;\n    if (_6757 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6757 * _6757), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6748, _6753) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6817 = a.z > 0.0;\n    bool _6821 = b.z > 0.0;\n    if (_6817 && _6821)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6817 != _6821)\n        {\n            vec3 _6856 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6856.z = 0.0;\n            if (_6817)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6856;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6856;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6856;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6856;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6905 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6931 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6957 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6983 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6905;\n    vec3 param_1 = _6931;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6931;\n    vec3 param_7 = _6957;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6957;\n    vec3 param_13 = _6983;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6983;\n    vec3 param_19 = _6905;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7151 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7169;\n    for (int k = 0; k < (2 * _7151); k++)\n    {\n        bool _7166 = k >= _7151;\n        if (_7166)\n        {\n            _7169 = k - _7151;\n        }\n        else\n        {\n            _7169 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7151 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7215 = 2 * _7169;\n            int param_4 = _7215 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7215 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7215 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7252 = bvec4(_7166);\n        vec4 param_16 = vec4(_7252.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7252.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7252.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7252.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7263 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7166)\n        {\n            vec2 _10067 = sum;\n            _10067.y = _10067.y + _7263;\n            sum = _10067;\n        }\n        else\n        {\n            vec2 _10070 = sum;\n            _10070.x = _10070.x + _7263;\n            sum = _10070;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7287 = fa_light_base(param);\n    int param_1 = _7287;\n    int param_2 = _7287 + 1;\n    int param_3 = _7287 + 2;\n    int param_4 = _7287 + 4;\n    vec4 _7309 = fa_light_texel(param_4);\n    int param_5 = _7287 + 5;\n    vec4 _7314 = fa_light_texel(param_5);\n    int param_6 = _7287 + 6;\n    vec4 _7319 = fa_light_texel(param_6);\n    float _7320 = _7319.w;\n    vec3 _7325 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7327 = _7320 < 1.5;\n    bool _7334;\n    if (_7327)\n    {\n        _7334 = dot(normalize(fa_light_texel(param_3).xyz), _7325) >= 0.0;\n    }\n    else\n    {\n        _7334 = _7327;\n    }\n    if (_7334)\n    {\n        return vec3(0.0);\n    }\n    bool _7343 = (_7320 > 0.5) && _7327;\n    float _7347 = _7343 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7350 = _7309.xyz;\n    float _7352 = _7309.w;\n    vec3 _7358 = _7314.xyz;\n    float _7360 = _7314.w;\n    vec3 up = _7358 * (_7360 * _7347);\n    float _7366;\n    if (_7343)\n    {\n        _7366 = (3.1415927410125732421875 * _7352) * _7352;\n    }\n    else\n    {\n        _7366 = (4.0 * _7352) * _7360;\n    }\n    if (_7320 > 1.5)\n    {\n        vec3 _7392 = cross(_7350, -_7325);\n        vec3 perp = _7392;\n        float _7396 = dot(_7392, _7392);\n        vec3 _7399;\n        if (_7396 > 1.0000000133514319600180897396058e-10)\n        {\n            _7399 = perp * inversesqrt(_7396);\n        }\n        else\n        {\n            _7399 = _7358;\n        }\n        perp = _7399;\n        up = _7399 * _7360;\n    }\n    float _7420 = max(_7366, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7430 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7430;\n    vec3 param_10 = n;\n    vec3 param_11 = _7325;\n    vec3 param_12 = _7430;\n    vec3 param_13 = n;\n    vec3 param_14 = _7350 * (_7352 * _7347);\n    vec3 param_15 = _7430;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7461 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7461;\n    vec2 param_21 = _7461 + vec2(64.0, 0.0);\n    vec4 _7471 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7320;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7483 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7483.x) + (((f0 * _7471.x) + ((vec3(f90) - f0) * _7471.y)) * _7483.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7325, _7325)) + _7420) / _7420) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5377 = 1.0 / alpha;\n    return ((2.0 + _5377) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5377)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5412 = max(dot(L.nc, l), 0.0);\n    float _5418 = max(dot(L.nc, h), 0.0);\n    float _5427 = ((_5418 * _5418) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5427) * _5427)) * (0.5 / max(mix((2.0 * _5412) * L.coat_ndv, _5412 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5412)) * _5412;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7520;\n    if (L.sheen_on)\n    {\n        _7520 = L.sheen_scale;\n    }\n    else\n    {\n        _7520 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7520);\n    vec3 _7533 = normalize(l + v);\n    int param = li;\n    vec3 _7544 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7553 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7533), 0.0);\n        float param_3 = _7553;\n        float param_4 = ndv;\n        result += ((L.sheen * _7544) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7553)) * _7553) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7533;\n        float param_8 = max(dot(v, _7533), 0.0);\n        result += (_7544 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5280 = tdh / at;\n    float _5284 = bdh / ab;\n    float _5296 = ((_5280 * _5280) + (_5284 * _5284)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5296) * _5296);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5476 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5555 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5555) * _5555);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5476);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5476));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4679 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4682 = _4679.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4682 * _4682, exp2((-9.27999973297119140625) * ndv)) * _4682) + _4679.y)) + _4679.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3990;\n    if (lv == 0)\n    {\n        _3990 = 0.0;\n    }\n    else\n    {\n        _3990 = res + 2.0;\n    }\n    float _4000;\n    if (lv == 0)\n    {\n        _4000 = 0.0;\n    }\n    else\n    {\n        _4000 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3990, _4000)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4046;\n    if (res > 64.5)\n    {\n        _4046 = 5.0;\n    }\n    else\n    {\n        _4046 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4061 = clamp(rough, 0.0, 1.0) * (_4046 - 1.0);\n    int _4068 = int(min(floor(_4061), _4046 - 2.0));\n    float _4073 = _4061 - float(_4068);\n    vec3 param = d;\n    vec2 _4077 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4068;\n    vec2 param_4 = _4077;\n    vec3 _4087 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4073 < 0.00200000009499490261077880859375)\n    {\n        return _4087;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4068 + 1;\n    vec2 param_8 = _4077;\n    return mix(_4087, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4073));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4158 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4165 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4172 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4178 = dot(bx.xyz, d);\n    float _4182 = dot(by.xyz, d);\n    float _4186 = dot(bz.xyz, d);\n    float _4192;\n    if (_4178 > 9.9999999747524270787835121154785e-07)\n    {\n        _4192 = (1.0 - _4158) / _4178;\n    }\n    else\n    {\n        float _4206;\n        if (_4178 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4206 = ((-1.0) - _4158) / _4178;\n        }\n        else\n        {\n            _4206 = 1000000015047466219876688855040.0;\n        }\n        _4192 = _4206;\n    }\n    float tx = _4192;\n    float _4223;\n    if (_4182 > 9.9999999747524270787835121154785e-07)\n    {\n        _4223 = (1.0 - _4165) / _4182;\n    }\n    else\n    {\n        float _4236;\n        if (_4182 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4236 = ((-1.0) - _4165) / _4182;\n        }\n        else\n        {\n            _4236 = 1000000015047466219876688855040.0;\n        }\n        _4223 = _4236;\n    }\n    float ty = _4223;\n    float _4252;\n    if (_4186 > 9.9999999747524270787835121154785e-07)\n    {\n        _4252 = (1.0 - _4172) / _4186;\n    }\n    else\n    {\n        float _4265;\n        if (_4186 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4265 = ((-1.0) - _4172) / _4186;\n        }\n        else\n        {\n            _4265 = 1000000015047466219876688855040.0;\n        }\n        _4252 = _4265;\n    }\n    float _4277 = tx;\n    float _4280 = (_4277 > 0.0) ? _4277 : 1000000015047466219876688855040.0;\n    tx = _4280;\n    float _4281 = ty;\n    float _4284 = (_4281 > 0.0) ? _4281 : 1000000015047466219876688855040.0;\n    ty = _4284;\n    float _4294 = min(_4280, min(_4284, (_4252 > 0.0) ? _4252 : 1000000015047466219876688855040.0));\n    if (_4294 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4310 = (fa_world_pos + (d * _4294)) - posw.xyz;\n    vec3 _4315;\n    if (dot(_4310, _4310) > 1.0000000133514319600180897396058e-10)\n    {\n        _4315 = normalize(_4310);\n    }\n    else\n    {\n        _4315 = d;\n    }\n    return _4315;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4361 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4361 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4389 = rough * rough;\n            float _4420 = 0.60000002384185791015625 * _4389;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4389)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4420, 0.0500000007450580596923828125 + _4420, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4389 * 0.60000002384185791015625));\n        }\n        outc = base * _4361;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4479 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4479 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4511 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4511 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5157;\n        if (L.aniso >= 0.0)\n        {\n            _5157 = L.b;\n        }\n        else\n        {\n            _5157 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5157, v), _5157), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5193 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5193.x) + (vec3(L.f90) * _5193.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5251 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5251.x) + _5251.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4721 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4721.x) + vec3(_4721.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5953 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5957 = fa_xm_origin(param_1);\n    vec2 _5963 = (uv * _5953) - vec2(0.5);\n    vec2 _5966 = fract(_5963);\n    vec2 _5969 = floor(_5963);\n    vec2 param_2 = _5953;\n    vec2 param_3 = _5957;\n    vec2 param_4 = _5969;\n    vec2 param_5 = _5953;\n    vec2 param_6 = _5957;\n    vec2 param_7 = _5969 + vec2(1.0, 0.0);\n    vec2 param_8 = _5953;\n    vec2 param_9 = _5957;\n    vec2 param_10 = _5969 + vec2(0.0, 1.0);\n    vec2 param_11 = _5953;\n    vec2 param_12 = _5957;\n    vec2 param_13 = _5969 + vec2(1.0);\n    vec3 _6011 = vec3(_5966.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6011), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6011), vec3(_5966.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6030 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6034 = clamp(lod, 0.0, _6030);\n    int _6038 = int(floor(_6034));\n    int param = _6038;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6048 = float(_6038);\n    float _6049 = _6034 - _6048;\n    bool _6051 = _6049 > 0.001000000047497451305389404296875;\n    bool _6058;\n    if (_6051)\n    {\n        _6058 = _6048 < _6030;\n    }\n    else\n    {\n        _6058 = _6051;\n    }\n    if (_6058)\n    {\n        int param_2 = _6038 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6049));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6084 = fa_env_brdf(param, param_1);\n    vec3 _6108 = ((vec3(1.0) - clamp((f0 * _6084.x) + (vec3(f90) * _6084.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6108;\n    float _6114 = max(s.thickness, 0.0);\n    bool _6119 = _6114 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6119)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6114);\n    }\n    bool _6144 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6150;\n    if (_6144)\n    {\n        _6150 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6150 = _6144;\n    }\n    bool _6157;\n    if (!_6150)\n    {\n        _6157 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6157 = _6150;\n    }\n    if (_6157)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6172 = vec4(fa_world_pos, 1.0);\n    float _6177 = dot(fa_mesh_fs_params[28], _6172);\n    vec2 uv0 = vec2(0.5);\n    if (_6177 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6195 = vec2(dot(fa_mesh_fs_params[26], _6172), dot(fa_mesh_fs_params[27], _6172)) / vec2(_6177);\n        float _6203;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6203 = (_6195.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6203 = 0.5 - (_6195.y * 0.5);\n        }\n        uv0 = vec2((_6195.x * 0.5) + 0.5, _6203);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6224 = fa_xm_size(param_2);\n        vec2 _6232 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6224);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6232), 0).w > 0.5)\n        {\n            int _6252 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6275 = abs(dx) > _6252;\n                    bool _6283;\n                    if (!_6275)\n                    {\n                        _6283 = abs(dy) > _6252;\n                    }\n                    else\n                    {\n                        _6283 = _6275;\n                    }\n                    if (_6283)\n                    {\n                        continue;\n                    }\n                    vec4 _6304 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6232 + vec2(float(dx), float(dy)), vec2(0.0), _6224 - vec2(1.0))), 0);\n                    if (_6304.w > 0.5)\n                    {\n                        acc += _6304.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6108 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6119)\n    {\n        vec4 _6352 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6114), 1.0);\n        float _6357 = dot(fa_mesh_fs_params[28], _6352);\n        uv = vec2(0.5);\n        if (_6357 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6374 = vec2(dot(fa_mesh_fs_params[26], _6352), dot(fa_mesh_fs_params[27], _6352)) / vec2(_6357);\n            float _6382;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6382 = (_6374.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6382 = 0.5 - (_6374.y * 0.5);\n            }\n            uv = vec2((_6374.x * 0.5) + 0.5, _6382);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3286 = int(fa_shadows[25].x + 0.5);\n    float _3296 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3301 = _3286 > 0;\n    bool _3310;\n    if (_3301)\n    {\n        int param = _3286 - 1;\n        _3310 = _3296 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3310 = _3301;\n    }\n    if (_3310)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3316 = _3286 > 1;\n        bool _3323;\n        if (_3316)\n        {\n            _3323 = _3296 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3323 = _3316;\n        }\n        if (_3323)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3329 = _3286 > 2;\n        bool _3336;\n        if (_3329)\n        {\n            _3336 = _3296 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3336 = _3329;\n        }\n        if (_3336)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3342 = _3286 > 3;\n        bool _3349;\n        if (_3342)\n        {\n            _3349 = _3296 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3349 = _3342;\n        }\n        if (_3349)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9473 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9473 = -_9473;\n    }\n    vec3 _8771 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9473, fa_world_tangent, fa_uv, fa_vertex_color, _8771, gl_FrontFacing);\n    Surface _8779 = fa_standard_surface(param_1);\n    vec3 _9504 = _8779.albedo;\n    float _9505 = _8779.alpha;\n    vec3 _9506 = _8779.normal;\n    float _9507 = _8779.metallic;\n    float _9508 = _8779.roughness;\n    float _9509 = _8779.occlusion;\n    vec3 _9510 = _8779.emission;\n    float _9511 = _8779.clearcoat;\n    float _9512 = _8779.clearcoat_roughness;\n    vec3 _9513 = _8779.sheen_color;\n    float _9514 = _8779.sheen_roughness;\n    float _9515 = _8779.anisotropy;\n    float _9516 = _8779.anisotropy_rotation;\n    float _9517 = _8779.specular;\n    float _9518 = _8779.ior;\n    vec3 _9519 = _8779.specular_color;\n    float _9520 = _8779.transmission;\n    float _9521 = _8779.thickness;\n    vec3 _9522 = _8779.attenuation_color;\n    float _9523 = _8779.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9473, fa_world_tangent, fa_uv, fa_vertex_color, _8771, gl_FrontFacing);\n    Surface param_3 = _8779;\n    surface(param_2, param_3);\n    _9504 = param_3.albedo;\n    _9505 = param_3.alpha;\n    _9506 = param_3.normal;\n    _9507 = param_3.metallic;\n    _9508 = param_3.roughness;\n    _9509 = param_3.occlusion;\n    _9510 = param_3.emission;\n    _9511 = param_3.clearcoat;\n    _9512 = param_3.clearcoat_roughness;\n    _9513 = param_3.sheen_color;\n    _9514 = param_3.sheen_roughness;\n    _9515 = param_3.anisotropy;\n    _9516 = param_3.anisotropy_rotation;\n    _9517 = param_3.specular;\n    _9518 = param_3.ior;\n    _9519 = param_3.specular_color;\n    _9520 = param_3.transmission;\n    _9521 = param_3.thickness;\n    _9522 = param_3.attenuation_color;\n    _9523 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9473;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9504 = param_6;\n    _9506 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9504;\n    }\n    else\n    {\n        vec3 _8819 = normalize(_9506);\n        float _8826 = clamp(_9507, 0.0, 1.0);\n        float _8830 = clamp(_9508, 0.0500000007450580596923828125, 1.0);\n        float _8834 = _8830 * _8830;\n        float _8838 = _8834 * _8834;\n        float _8843 = max(dot(_8819, _8771), 9.9999997473787516355514526367188e-05);\n        float _8849 = 1.0 - _8826;\n        float _8850 = clamp(_9520, 0.0, 1.0) * _8849;\n        vec3 _8859 = (_9504 * _8849) * (1.0 - _8850);\n        vec3 _8866 = mix(vec3(0.039999999105930328369140625), _9504, vec3(_8826));\n        vec3 f0 = _8866;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9473, fa_world_tangent, fa_uv, fa_vertex_color, _8771, gl_FrontFacing);\n        Surface param_9 = Surface(_9504, _9505, _9506, _9507, _9508, _9509, _9510, _9511, _9512, _9513, _9514, _9515, _9516, _9517, _9518, _9519, _9520, _9521, _9522, _9523);\n        vec3 param_10 = _8819;\n        vec3 param_11 = _8771;\n        float param_12 = _8826;\n        float param_13 = _8830;\n        vec3 param_14 = _8866;\n        FaLayers _8882 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8819;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8859) * _9509;\n        if (_8882.on)\n        {\n            lit *= _8882.base_scale;\n        }\n        int _8904 = fa_cl_ndir + fa_cl_local;\n        float _8969;\n        for (int ln = 0; ln < _8904; ln++)\n        {\n            int param_16 = ln;\n            int _8917 = fa_cl_light(param_16);\n            int param_17 = _8917;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8917;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9473;\n            LightSample _8933 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8941 = max(dot(_8819, _8933.direction), 0.0);\n            float _8947 = _8933.attenuation * _8933.shadow;\n            vec3 _8952 = normalize(_8933.direction + _8771);\n            float _8957 = max(dot(_8819, _8952), 0.0);\n            float _8962 = max(dot(_8771, _8952), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8882.on)\n                {\n                    _8969 = _8882.f90;\n                }\n                else\n                {\n                    _8969 = 1.0;\n                }\n                int param_21 = _8917;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8819;\n                vec3 param_24 = _8771;\n                vec3 param_25 = _8859;\n                vec3 param_26 = f0;\n                float param_27 = _8969;\n                float param_28 = _8830;\n                float param_29 = _8843;\n                float param_30 = _8947;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8882.on)\n                {\n                    FaLayers param_31 = _8882;\n                    vec3 param_32 = area;\n                    int param_33 = _8917;\n                    vec3 param_34 = _8819;\n                    vec3 param_35 = _8771;\n                    vec3 param_36 = _8933.direction;\n                    float param_37 = _8843;\n                    float param_38 = _8947;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8882.on)\n                {\n                    FaLayers param_39 = _8882;\n                    vec3 param_40 = _8859;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8819;\n                    vec3 param_43 = _8771;\n                    vec3 param_44 = _8933.direction;\n                    vec3 param_45 = _8952;\n                    float param_46 = _8941;\n                    float param_47 = _8843;\n                    float param_48 = _8957;\n                    float param_49 = _8962;\n                    float param_50 = _8834;\n                    float param_51 = _8838;\n                    int param_52 = _8917;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8947));\n                }\n                else\n                {\n                    float _9071 = ((_8957 * _8957) * (_8838 - 1.0)) + 1.0;\n                    int param_53 = _8917;\n                    lit += (((_8859 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8962, 5.0))) * (((_8838 / ((3.1415927410125732421875 * _9071) * _9071)) * (0.5 / max(mix((2.0 * _8941) * _8843, _8941 + _8843, _8834), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8941))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8941 * _8947));\n                }\n            }\n        }\n        if (_8882.on)\n        {\n            FaLayers param_54 = _8882;\n            vec3 param_55 = _8819;\n            vec3 param_56 = _8771;\n            vec3 param_57 = f0;\n            float param_58 = _8830;\n            float param_59 = _9509;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8819;\n            vec3 param_61 = _8771;\n            vec3 param_62 = f0;\n            float param_63 = _8830;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9509);\n        }\n        if (_8850 > 0.0)\n        {\n            float _9169;\n            if (_8882.on)\n            {\n                _9169 = _8882.f90;\n            }\n            else\n            {\n                _9169 = 1.0;\n            }\n            float _9177;\n            if (_8882.on)\n            {\n                _9177 = _8882.base_scale;\n            }\n            else\n            {\n                _9177 = 1.0;\n            }\n            Surface param_64 = Surface(_9504, _9505, _9506, _9507, _9508, _9509, _9510, _9511, _9512, _9513, _9514, _9515, _9516, _9517, _9518, _9519, _9520, _9521, _9522, _9523);\n            vec3 param_65 = _8819;\n            vec3 param_66 = _8771;\n            float param_67 = _8830;\n            vec3 param_68 = f0;\n            float param_69 = _9169;\n            float param_70 = _9177;\n            float param_71 = _8850;\n            float param_72 = fa_tr_blend;\n            vec3 _9201 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9201;\n        }\n        result = lit;\n    }\n    vec3 _9208 = result;\n    vec3 _9209 = _9208 + _9510;\n    result = _9209;\n    vec3 param_73 = _9209;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9218 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9225;\n    if (!_9218)\n    {\n        _9225 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9225 = _9218;\n    }\n    if (_9225)\n    {\n        vec3 _9234 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9240 = dot(_9234, fa_mesh_fs_params[9].xyz);\n        bool _9244 = fa_mesh_fs_params[9].w > 0.5;\n        float _9245;\n        if (_9244)\n        {\n            _9245 = _9240;\n        }\n        else\n        {\n            _9245 = length(_9234);\n        }\n        float _9257 = _9245 - fa_mesh_fs_params[8].x;\n        if (_9257 > 0.0)\n        {\n            float _9266 = fa_mesh_fs_params[7].w * _9257;\n            float tau = _9266 * _9266;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9282;\n                if (_9244)\n                {\n                    _9282 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9240);\n                }\n                else\n                {\n                    _9282 = fa_mesh_fs_params[0].y;\n                }\n                float _9303 = mix(_9282, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9245, 0.0, 1.0));\n                float _9307 = fa_world_pos.y - _9303;\n                float _9312 = _9303 - fa_mesh_fs_params[8].z;\n                float _9317 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9320 = _9312 <= 0.0;\n                bool _9321 = !_9320;\n                bool _9327;\n                if (_9321)\n                {\n                    _9327 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9327 = _9320;\n                }\n                float _9328;\n                if (_9327)\n                {\n                    _9328 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9328 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9312, 80.0));\n                }\n                bool _9355;\n                if (_9321)\n                {\n                    _9355 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9355 = _9320;\n                }\n                float _9356;\n                if (_9355)\n                {\n                    _9356 = fa_mesh_fs_params[8].y * _9312;\n                }\n                else\n                {\n                    _9356 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9312, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9381 = _9317 <= 0.0;\n                bool _9388;\n                if (!_9381)\n                {\n                    _9388 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9388 = _9381;\n                }\n                float _9389;\n                if (_9388)\n                {\n                    _9389 = fa_mesh_fs_params[8].y * _9317;\n                }\n                else\n                {\n                    _9389 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9317, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9416;\n                if (abs(_9307) < 0.001000000047497451305389404296875)\n                {\n                    _9416 = _9328;\n                }\n                else\n                {\n                    _9416 = (_9389 - _9356) / _9307;\n                }\n                tau += (_9257 * max(_9416, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9452 = 1.0 - fa_tr_blend;\n        result /= vec3(_9452);\n        _9505 *= _9452;\n    }\n    fa_frag_color = vec4(result, _9505);\n}\n\n",
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
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
            "inst_name": "_205",
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
            "inst_name": "_665",
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
            "inst_name": "_2327",
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
            "inst_name": "_7621",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) out vec3 fa_vel_cur;\nlayout(location = 12) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _121 = cross(model[1].xyz, model[2].xyz);\n    float _125 = (dot(model[0].xyz, _121) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_121 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _125, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _125), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _252;\n    if (has_prev)\n    {\n        _252 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _252 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _275 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _282 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_275 * _282).z;\n    fa_pre_r0 = vec3(_275[0].x, _275[1].x, _275[2].x);\n    fa_pre_r1 = vec3(_275[0].y, _275[1].y, _275[2].y);\n    fa_pre_r2 = vec3(_275[0].z, _275[1].z, _275[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _282;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_252)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _282).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nlayout(location = 11) in vec3 fa_vel_cur;\nlayout(location = 12) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _269 = fa_tex_fix(param_2, param_3);\n    vec4 _876 = base_t;\n    _876.x = _269.x;\n    _876.y = _269.y;\n    _876.z = _269.z;\n    base_t = _876;\n    vec4 _285 = (_876 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _831 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _320 = fa_tex_fix(param_6, param_7);\n        vec3 _324 = (_320 * 2.0) - vec3(1.0);\n        vec2 _329 = _324.xy * fa_mesh_fs_params[6].x;\n        vec3 _884 = _324;\n        _884.x = _329.x;\n        _884.y = _329.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _884;\n        _831 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _360 = fa_tex_fix(param_12, param_13);\n    vec4 _887 = mrt;\n    _887.x = _360.x;\n    _887.y = _360.y;\n    _887.z = _360.z;\n    mrt = _887;\n    vec4 _392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _404 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _436 = fa_tex_fix(param_20, param_21);\n    float _836 = fa_mesh_fs_params[20].x;\n    float _837 = fa_mesh_fs_params[20].y;\n    float _840 = fa_mesh_fs_params[20].z;\n    float _839 = fa_mesh_fs_params[21].w;\n    float _842 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _836 *= _404.y;\n            _837 *= _404.z;\n            _839 *= _392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _840 *= mrt.x;\n            _842 *= mrt.w;\n        }\n    }\n    return Surface(_285.xyz, _285.w, _831, clamp(fa_mesh_fs_params[5].x * _360.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _360.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_404.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _436), _836, _837, fa_mesh_fs_params[21].xyz, _839, _840, fa_mesh_fs_params[20].w, _842, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _726 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _726 = -_726;\n    }\n    vec3 _587 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _602 = normalize(param_2.normal);\n    vec3 _617 = normalize(vec3(dot(fa_pre_r0, _602), dot(fa_pre_r1, _602), dot(fa_pre_r2, _602)));\n    float _629 = _617.z;\n    vec2 e = _617.xy / vec2((abs(_617.x) + abs(_617.y)) + abs(_629));\n    if (_629 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _673 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _680;\n    if (_673)\n    {\n        _680 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _680 = _673;\n    }\n    if (_680)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
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
            "inst_name": "_68",
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
            "inst_name": "_246",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_254",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) out vec3 fa_vel_cur;\nlayout(location = 12) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 13) in vec4 fa_prev_r0;\nlayout(location = 14) in vec4 fa_prev_r1;\nlayout(location = 15) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _225 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_225 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_225 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_225 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _137 = cross(model[1].xyz, model[2].xyz);\n    float _141 = (dot(model[0].xyz, _137) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_137 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _141, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _141), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _353 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _353;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _353 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _353 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _496;\n    if (has_prev)\n    {\n        _496 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _496 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _519 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _526 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_519 * _526).z;\n    fa_pre_r0 = vec3(_519[0].x, _519[1].x, _519[2].x);\n    fa_pre_r1 = vec3(_519[0].y, _519[1].y, _519[2].y);\n    fa_pre_r2 = vec3(_519[0].z, _519[1].z, _519[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _526;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_496)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _526).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nlayout(location = 11) in vec3 fa_vel_cur;\nlayout(location = 12) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _269 = fa_tex_fix(param_2, param_3);\n    vec4 _876 = base_t;\n    _876.x = _269.x;\n    _876.y = _269.y;\n    _876.z = _269.z;\n    base_t = _876;\n    vec4 _285 = (_876 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _831 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _320 = fa_tex_fix(param_6, param_7);\n        vec3 _324 = (_320 * 2.0) - vec3(1.0);\n        vec2 _329 = _324.xy * fa_mesh_fs_params[6].x;\n        vec3 _884 = _324;\n        _884.x = _329.x;\n        _884.y = _329.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _884;\n        _831 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _360 = fa_tex_fix(param_12, param_13);\n    vec4 _887 = mrt;\n    _887.x = _360.x;\n    _887.y = _360.y;\n    _887.z = _360.z;\n    mrt = _887;\n    vec4 _392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _404 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _436 = fa_tex_fix(param_20, param_21);\n    float _836 = fa_mesh_fs_params[20].x;\n    float _837 = fa_mesh_fs_params[20].y;\n    float _840 = fa_mesh_fs_params[20].z;\n    float _839 = fa_mesh_fs_params[21].w;\n    float _842 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _836 *= _404.y;\n            _837 *= _404.z;\n            _839 *= _392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _840 *= mrt.x;\n            _842 *= mrt.w;\n        }\n    }\n    return Surface(_285.xyz, _285.w, _831, clamp(fa_mesh_fs_params[5].x * _360.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _360.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_404.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _436), _836, _837, fa_mesh_fs_params[21].xyz, _839, _840, fa_mesh_fs_params[20].w, _842, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _726 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _726 = -_726;\n    }\n    vec3 _587 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _602 = normalize(param_2.normal);\n    vec3 _617 = normalize(vec3(dot(fa_pre_r0, _602), dot(fa_pre_r1, _602), dot(fa_pre_r2, _602)));\n    float _629 = _617.z;\n    vec2 e = _617.xy / vec2((abs(_617.x) + abs(_617.y)) + abs(_629));\n    if (_629 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _673 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _680;\n    if (_673)\n    {\n        _680 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _680 = _673;\n    }\n    if (_680)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 14,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 15,
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
            "inst_name": "_85",
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
            "inst_name": "_234",
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
            "inst_name": "_491",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_254",
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
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_187 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_187 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_187 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
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
            "inst_name": "_196",
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

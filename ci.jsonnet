{
    Windows:: {
        capabilities+: ["windows"],
        name+: "-windows",
        environment+: {
            CI_OS: "windows"
        },
        packages+: {
            msvc: "==10.0",
        },
    },
    Linux:: {
        packages+: {
            git: ">=1.8.3",
            mercurial: ">=2.2",
            make : ">=3.83",
            "gcc-build-essentials" : "==4.9.1"
        },
        capabilities+: ["linux"],
        name+: "-linux",
        environment+: {
            CI_OS: "linux"
        }
    },
    Solaris:: {
        packages+: {
            git: ">=1.8.3",
            mercurial: ">=2.2",
            make : ">=3.83",
            solarisstudio: "==12.3"
        },
        capabilities+: ["solaris"],
        name+: "-solaris",
        environment+: {
            CI_OS: "solaris"
        }
    },
    Darwin:: {
        packages+: {
            # No need to specify a "make" package as Mac OS X has make 3.81
            # available once Xcode has been installed.
        },
        environment+: {
            CI_OS: "darwin",
            ac_cv_func_basename_r: "no",
            ac_cv_func_clock_getres: "no",
            ac_cv_func_clock_gettime: "no",
            ac_cv_func_clock_settime: "no",
            ac_cv_func_dirname_r: "no",
            ac_cv_func_getentropy: "no",
            ac_cv_func_mkostemp: "no",
            ac_cv_func_mkostemps: "no",
            MACOSX_DEPLOYMENT_TARGET: "10.11"
        },
        capabilities+: ["darwin_sierra", "macmini_late_2014_8gb"],
        name+: "-darwin",
    },

    AMD64:: {
        capabilities+: ["amd64"],
        name+: "-amd64",
        environment+: {
            CI_ARCH: "amd64"
        }
    },
    SPARCv9:: {
        capabilities+: ["sparcv9"],
        name+: "-sparcv9",
        timelimit: "1:30:00",
        environment+: {
            CI_ARCH: "sparcv9"
        }
    },

    Eclipse:: {
        downloads+: {
            ECLIPSE: {
                name: "eclipse",
                version: "4.5.2",
                platformspecific: true
            }
        },
        environment+: {
            ECLIPSE_EXE: "$ECLIPSE/eclipse"
        },
    },

    JDT:: {
        downloads+: {
            JDT: {
                name: "ecj",
                version: "4.5.1",
                platformspecific: false
            }
        }
    },

    OracleJDK:: {
        name+: "-oraclejdk",
        downloads: {
            JAVA_HOME: {
                name : "oraclejdk",
                version : "8u202",
                platformspecific: true
            }
        }
    },

    OpenJDK:: {
        name+: "-openjdk",
        downloads: {
            JAVA_HOME: {
                name : "openjdk",
                version : "8u202",
                platformspecific: true
            }
        }
    },

    Build:: {
        packages+: {
            "pip:astroid" : "==1.1.0",
            "pip:pylint" : "==1.1.0",
        },
        name: "gate-jvmci",
        timelimit: "1:00:00",
        diskspace_required: "10G",
        logs: ["*.log"],
        targets: ["gate"],
        run: [
            ["mx", "-v", "--kill-with-sigquit", "--strict-compliance", "gate", "--dry-run"],
            ["mx", "-v", "--kill-with-sigquit", "--strict-compliance", "gate"],

            ["set-export", "JAVA_HOME", ["mx", "--vm=server", "jdkhome"]],

            # Test on graal
            ["git", "clone", ["mx", "urlrewrite", "https://github.com/graalvm/graal.git"]],

            # Look for a well known branch that fixes a downstream failure caused by a JDK change
            ["git", "-C", "graal", "checkout", "master", "||", "true"]
        ],
    },

    GraalTest:: {
        name+: "-graal",
        run+: [
            ["mx", "-v", "-p", "graal/compiler",
                    "gate", "--tags", "build,test,bootstraplite"
            ]
        ]
    },

    # Build a basic GraalVM and run some simple tests.
    GraalVMTest:: {
        name+: "-graalvm",
        timelimit: "1:20:00",
        run+: [
            ["mx", "-p", "graal/vm",
                    "--dy", "/substratevm,/graal-js",
                    "--force-bash-launchers=true",
                    "--disable-libpolyglot", "build"
            ],
            ["./graal/vm/latest_graalvm_home/bin/gu", "rebuild-images", "js"],
            ["./graal/vm/latest_graalvm_home/bin/js",          "mx.jvmci/test.js"],
            ["./graal/vm/latest_graalvm_home/bin/js", "--jvm", "mx.jvmci/test.js"],

            ["mx", "-p", "graal/vm", "--env", "libgraal", "--extra-image-builder-argument=-J-esa", "build"],
            ["mx", "-p", "graal/vm", "--env", "libgraal", "gate", "--task", "LibGraal"]
        ]
    },

    builds: [
        self.Build + self.GraalTest + mach
        for mach in [
            # Only need to test formatting and building
            # with Eclipse on one platform.
            self.GraalVMTest + self.Linux + self.AMD64 + self.OracleJDK + self.Eclipse + self.JDT,
            self.GraalVMTest + self.Linux + self.AMD64 + self.OpenJDK,
            self.GraalVMTest + self.Darwin + self.AMD64 + self.OracleJDK,
            self.GraalVMTest + self.Darwin + self.AMD64 + self.OpenJDK,
            # GraalVM not (yet) supported on these platforms
            self.Windows + self.AMD64 + self.OracleJDK,
            self.Windows + self.AMD64 + self.OpenJDK,
            self.Solaris + self.SPARCv9 + self.OracleJDK,
        ]
    ]
}

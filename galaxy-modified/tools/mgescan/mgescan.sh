#!/bin/bash
# mgescan.sh $input $input.name 3 $output L None None None $ltr_gff3 None $sw_rm "$scaffold" $min_dist $max_dist $min_len_ltr $max_len_ltr $ltr_sim_condition $cluster_sim_condition $len_condition $repeatmasker
user_dir=/u/lee212
#script=$user_dir/retrotminer/wazim/MGEScan1.1/run_MGEScan.pl
#script=$user_dir/retrotminer/wazim/MGEScan1.3.1/run_MGEScan2.pl
source $user_dir/virtualenv/retrotminer/bin/activate
script_program=`which python`
script=$user_dir/github/retrotminer/retrotminer/retrotminer.py
input_file=$1
input_file_name=$2
hmmsearch_version=$3
output_file=$4
program=$5 # N is nonLTR, L is LTR and B is both
# Optional output parameters for nonLTR
clade=$6
en=$7
rt=$8
ltr_gff3=$9
nonltr_gff3=${10}
both_gff3=${11}
#### for ltr between $11 and $20
sw_rm=${12}
scaffold=${13}
min_dist=${14}
max_dist=${15}
min_len_ltr=${16}
max_len_ltr=${17}
ltr_sim_condition=${18}
cluster_sim_condition=${19}
len_condition=${20}
repeatmasker=${21}

# /nfs/nfs4/home/lee212/retrotminer/galaxy-dist/tools/retrotminer/find_ltr.sh /nfs/nfs4/home/lee212/retrotminer/galaxy-dist/database/files/000/dataset_1.dat /nfs/nfs4/home/lee212/retrotminer/galaxy-dist/database/files/000/dataset_3.dat

#load env?
source $user_dir/.bashrc
source $user_dir/.bash_profile

#set path for transeq
export PATH=$user_dir/retrotminer/EMBOSS/bin:/usr/bin:$PATH

#move to the working directory
work_dir=`dirname $script`
cd $work_dir

#create directory for input and output
mkdir -p input
t_dir=`mktemp -p input -d` #relative path
input_dir="$work_dir/$t_dir/seq" # full path
output_dir="$work_dir/$t_dir/data"
mkdir -p $input_dir
mkdir -p $output_dir

#make a copy of input
/bin/cp $input_file $input_dir/$input_file_name

if [ "2" == "$hmmsearch_version" ]
then
	export PATH=$user_dir/retrotminer/HMMER2.0/bin:$PATH
else
	export PATH=/usr/bin:$PATH
fi

if [ "$program" == "L" ]
then
	program_name="ltr"
else
	programname="nonltr"
fi

#run
$script_program $script $program_name $input_dir/ --output=$output_dir/ #-hmmerv=$hmmsearch_version -sw_rm=${11} -scaffold=${12} -min_dist=${13} -max_dist=${14} -min_len_ltr=${15} -max_len_ltr=${16} -ltr_sim_condition=${17} -cluster_sim_condition=${18} -len_condition=${19}
#/usr/bin/perl $script -genome=$input_dir/ -data=$output_dir/ -hmmerv=$hmmsearch_version -program=$program -sw_rm=${11} -scaffold=${12} -min_dist=${13} -max_dist=${14} -min_len_ltr=${15} -max_len_ltr=${16} -ltr_sim_condition=${17} -cluster_sim_condition=${18} -len_condition=${19}

#RES=`ssh -i $user_dir/.ssh/.internal silo.cs.indiana.edu "/usr/bin/perl $script -genome=$input_dir/ -data=$output_dir/ -hmmerv=$hmmsearch_version -program=$program > /dev/null"`

#make a copy of output
if [ "$program" != "N" ]
then
	/bin/cp $output_dir/ltr/ltr.out $output_file
	if [ "$ltr_gff3" != "None" ]
	then
		/bin/cp $output_dir/ltr/ltr.gff3 $ltr_gff3
	fi

	if [ "$repeatmasker" != "None" ] && [ "$repeatmasker" != "" ]
	then
		# chr2L.fa.cat.gz  chr2L.fa.masked  chr2L.fa.out  chr2L.fa.out.pos  chr2L.fa.tbl
		/bin/cp $output_dir/repeatmasker/${input_file_name}.out $repeatmasker
	fi
fi
if [ "$program" != "L" ]
then

	tmp=`mktemp`
	RANDOM=`basename $tmp`
	compressed_file=$output_dir/$RANDOM.tar.gz
	/bin/tar cvzfP $compressed_file $output_dir/info
	#/bin/cp $compressed_file $output_file
	#RES=`/bin/cp $output_dir/info/full/*/* $clade 2> /dev/null`
	RES=`/bin/cp $compressed_file $clade 2> /dev/null`
	RES=`/bin/cp $output_dir/info/validation/en $en 2> /dev/null`
	RES=`/bin/cp $output_dir/info/validation/rt $rt 2> /dev/null`
	if [ "$nonltr_gff3" != "None" ]
	then
		/bin/cp $output_dir/info/nonltr.gff3 $nonltr_gff3
		# nonltr.gff3
		##gff-version 3
		#chr2L.fa        MGEScan_nonLTR  mobile_genetic_element  19670384        19676921        .       .       .       ID=chr2L.fa_19670384
		#chr2L.fa        MGEScan_nonLTR  mobile_genetic_element  17689430        17695994        .       .       .       ID=chr2L.fa_17689430
		#chr2L.fa        MGEScan_nonLTR  mobile_genetic_element  11897186        11903717        .       .       .       ID=chr2L.fa_11897186
		#chr2L.fa        MGEScan_nonLTR  mobile_genetic_element  49574   56174   .       .       .       ID=chr2L.fa_49574
	fi

#else
	# Both LTR, nonLTR executed
	#compressed_file=$output_dir/$RANDOM.tar.gz
	#/bin/tar cvzfP $compressed_file $output_dir
	#/bin/cp $compressed_file $output_file
fi

if [ "$program" == "B" ]
then
	/bin/cat $output_dir/info/ltr.gff3 $output_dir/info/nonltr.gff3 > $both_gff3
fi

# delete temp directory
if [ $? -eq 0 ]
then
	rm -rf $work_dir/$t_dir
	#echo
else
	#echo cp -pr $work_dir/$t_dir $work_dir/error-cases/
	cp -pr $work_dir/$t_dir $work_dir/error-cases/
fi
